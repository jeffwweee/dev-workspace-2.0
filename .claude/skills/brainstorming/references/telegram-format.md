# Telegram Question Format

## Multiple Choice Questions

Format with lettered options:

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "What should we build?

A) A web scraper for news sites
B) A CLI tool for file management
C) A bot for automated responses

Reply A, B, or C" $MSG_ID
```

Wait for next `[TG:...]` message with user's answer.

## Open-Ended Questions

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "What's the main goal of this feature?" $MSG_ID
```

## Design Review Questions

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "Does this approach look right?

- Uses PostgreSQL for storage
- REST API with Express
- React frontend

Reply yes/no or suggest changes" $MSG_ID
```

## Sending Design Docs

After design is complete:

```bash
~/dev-workspace-v2/scripts/send-file.sh pichu $CHAT_ID docs/plans/YYYY-MM-DD-feature-design.md "Design doc - please review" $MSG_ID
```

Possible responses:
- "Approved" → Proceed to writing-plans
- "Changes needed" → Revise and resend
- "Rejected" → Discuss alternatives
