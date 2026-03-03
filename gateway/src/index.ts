import express from 'express';
import Redis from 'ioredis';
import { execFileSync } from 'child_process';
import { mkdirSync, existsSync, readFileSync, writeFileSync } from 'fs';
import { join, basename } from 'path';
import { COMMANDS } from './commands.js';
import { convert } from 'telegram-markdown-v2';

const app = express();
app.use(express.json());

const redis = new Redis(process.env.REDIS_URL || 'redis://localhost:6379');
const TMUX_SESSION = process.env.TMUX_SESSION || 'cc-pichu:0.0';
const TMUX_DELAY_MS = parseInt(process.env.TMUX_DELAY_MS || '500', 10);
const FILES_DIR = join(process.cwd(), 'state', 'files');

// Ensure files directory exists
if (!existsSync(FILES_DIR)) {
  mkdirSync(FILES_DIR, { recursive: true });
}

// Helper to download file from Telegram
async function downloadTelegramFile(botToken: string, fileId: string, localPath: string): Promise<void> {
  // Get file info
  const fileInfoRes = await fetch(`https://api.telegram.org/bot${botToken}/getFile?file_id=${fileId}`);
  const fileInfo = await fileInfoRes.json();
  if (!fileInfo.ok) throw new Error(`getFile failed: ${fileInfo.description}`);

  // Download file content
  const fileUrl = `https://api.telegram.org/file/bot${botToken}/${fileInfo.result.file_path}`;
  const fileRes = await fetch(fileUrl);
  if (!fileRes.ok) throw new Error(`Download failed: ${fileRes.statusText}`);

  // Write to local file
  const buffer = Buffer.from(await fileRes.arrayBuffer());
  writeFileSync(localPath, buffer);
}

// Health check
app.get('/health', (_req, res) => res.json({ status: 'ok' }));

// Webhook endpoint - receives from Telegram, stores in Redis, injects to tmux
app.post('/webhook/:botId', async (req, res) => {
  const { botId } = req.params;
  const message = req.body.message;

  if (!message?.chat?.id) {
    res.status(400).json({ error: 'Invalid message format' });
    return;
  }

  const chatId = message.chat.id;
  const messageId = message.message_id;
  const text = message.text || message.caption || '';
  const username = message.from?.username || 'unknown';
  const replyTo = message.reply_to_message?.message_id || 0;

  // Get bot token for file downloads
  const botToken = process.env[`TELEGRAM_BOT_TOKEN_${botId.toUpperCase()}`];

  // Handle file (photo or document)
  let filePath = '';
  try {
    let file: { file_id: string; file_name?: string } | null = null;

    // Photo: array of sizes, use largest (last)
    if (message.photo?.length) {
      const largest = message.photo[message.photo.length - 1];
      file = { file_id: largest.file_id, file_name: `photo_${messageId}.jpg` };
    }
    // Document
    else if (message.document) {
      file = { file_id: message.document.file_id, file_name: message.document.file_name };
    }

    if (file && botToken) {
      const fileName = `${chatId}_${messageId}_${file.file_name}`;
      filePath = join(FILES_DIR, fileName);
      await downloadTelegramFile(botToken, file.file_id, filePath);
    }
  } catch (err) {
    console.error('File download failed:', err);
  }

  // Store in Redis for context
  await redis.hset(`tg:session:${chatId}`, {
    bot_id: botId,
    chat_id: chatId,
    username,
    last_message: text,
    last_activity: Date.now().toString()
  });

  // Inject to Pichu's tmux session
  // Format: [TG:chat_id:bot_id:msg_id:reply_to][FILE:/path] message
  try {
    const filePart = filePath ? `[FILE:${filePath}]` : '';
    const prefixed = `[TG:${chatId}:${botId}:${messageId}:${replyTo}]${filePart} ${text.replace(/\n/g, ' ')}`;
    execFileSync('tmux', ['send-keys', '-t', TMUX_SESSION, prefixed]);
    setTimeout(() => {
      try {
        execFileSync('tmux', ['send-keys', '-t', TMUX_SESSION, 'Enter']);
      } catch (err) {
        console.error('tmux Enter failed:', err);
      }
    }, TMUX_DELAY_MS);
  } catch (err) {
    console.error('tmux injection failed:', err);
  }

  res.json({ ok: true });
});

// Register endpoint - registers webhook and commands with Telegram
app.post('/register/:botId', async (req, res) => {
  const { botId } = req.params;

  const botToken = process.env[`TELEGRAM_BOT_TOKEN_${botId.toUpperCase()}`];
  if (!botToken) {
    res.status(400).json({ error: `Unknown bot: ${botId}` });
    return;
  }

  // Construct webhook URL from WEBHOOK_URL env var or HOST
  const webhookUrl = process.env.WEBHOOK_URL
    ? `${process.env.WEBHOOK_URL}/webhook/${botId}`
    : `${process.env.HOST || `http://localhost:${PORT}`}/webhook/${botId}`;

  try {
    // Register webhook with Telegram
    const webhookResponse = await fetch(
      `https://api.telegram.org/bot${botToken}/setWebhook`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: webhookUrl })
      }
    );

    const webhookResult = await webhookResponse.json();
    if (!webhookResult.ok) {
      console.error('setWebhook error:', webhookResult);
      res.status(500).json({ error: 'Failed to set webhook', details: webhookResult });
      return;
    }

    // Register commands with Telegram
    const commandsResponse = await fetch(
      `https://api.telegram.org/bot${botToken}/setMyCommands`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ commands: COMMANDS })
      }
    );

    const commandsResult = await commandsResponse.json();
    if (!commandsResult.ok) {
      console.error('setMyCommands error:', commandsResult);
      res.status(500).json({ error: 'Failed to set commands', details: commandsResult });
      return;
    }

    res.json({
      ok: true,
      webhook: webhookResult,
      commands: commandsResult,
      webhookUrl
    });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Failed to register bot' });
  }
});

// Reply endpoint - called by Pichu to send messages to Telegram
app.post('/reply', async (req, res) => {
  const { bot_id, chat_id, text, parse_mode = 'Markdown', reply_to_message_id } = req.body;

  if (!bot_id || !chat_id || !text) {
    res.status(400).json({ error: 'Missing required fields: bot_id, chat_id, text' });
    return;
  }

  const botToken = process.env[`TELEGRAM_BOT_TOKEN_${bot_id.toUpperCase()}`];
  if (!botToken) {
    res.status(400).json({ error: `Unknown bot: ${bot_id}` });
    return;
  }

  try {
    // Convert Markdown to MarkdownV2 format if needed
    const formattedText = parse_mode === 'Markdown' ? convert(text) : text;
    const effectiveParseMode = parse_mode === 'Markdown' ? 'MarkdownV2' : parse_mode;

    const payload: Record<string, unknown> = { chat_id, text: formattedText, parse_mode: effectiveParseMode };
    if (reply_to_message_id) payload.reply_to_message_id = reply_to_message_id;

    const response = await fetch(
      `https://api.telegram.org/bot${botToken}/sendMessage`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      }
    );

    const result = await response.json();
    if (!result.ok) {
      console.error('Telegram API error:', result);
      res.status(500).json(result);
      return;
    }
    res.json(result);
  } catch (err) {
    console.error('Reply error:', err);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// Send file endpoint - called by Pichu to send files to Telegram
app.post('/send-file', async (req, res) => {
  const { bot_id, chat_id, file_path, caption, reply_to_message_id } = req.body;

  if (!bot_id || !chat_id || !file_path) {
    res.status(400).json({ error: 'Missing required fields: bot_id, chat_id, file_path' });
    return;
  }

  const botToken = process.env[`TELEGRAM_BOT_TOKEN_${bot_id.toUpperCase()}`];
  if (!botToken) {
    res.status(400).json({ error: `Unknown bot: ${bot_id}` });
    return;
  }

  if (!existsSync(file_path)) {
    res.status(400).json({ error: 'File not found' });
    return;
  }

  try {
    const fileBuffer = readFileSync(file_path);
    const fileName = basename(file_path);

    const formData = new FormData();
    formData.append('chat_id', chat_id.toString());
    formData.append('document', new Blob([fileBuffer]), fileName);
    if (caption) formData.append('caption', caption);
    if (reply_to_message_id) formData.append('reply_to_message_id', reply_to_message_id.toString());

    const response = await fetch(
      `https://api.telegram.org/bot${botToken}/sendDocument`,
      { method: 'POST', body: formData }
    );

    const result = await response.json();
    if (!result.ok) {
      console.error('Telegram API error:', result);
      res.status(500).json(result);
      return;
    }
    res.json(result);
  } catch (err) {
    console.error('Send file error:', err);
    res.status(500).json({ error: 'Failed to send file' });
  }
});

const PORT = process.env.PORT || 3100;
app.listen(PORT, () => console.log(`Gateway listening on ${PORT}`));
