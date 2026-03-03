#!/usr/bin/env node

/**
 * Suggest Compact Script
 *
 * Based on strategic-compact concept. Suggests compact at:
 * - Threshold: 50 tool calls
 * - Reminder: every 25 calls after
 *
 * Usage: Called as PreToolUse hook for Edit|Write operations
 */

const COMPACT_THRESHOLD = 50;
const COMPACT_REMINDER_INTERVAL = 25;

// Track via simple file-based counter
const fs = require('fs');
const path = require('path');

const counterFile = path.join(__dirname, '..', '.compact-counter.json');

function getCounter() {
  try {
    const data = fs.readFileSync(counterFile, 'utf8');
    return JSON.parse(data);
  } catch {
    return { count: 0, lastReminder: 0 };
  }
}

function saveCounter(counter) {
  fs.writeFileSync(counterFile, JSON.stringify(counter));
}

function main() {
  const counter = getCounter();
  counter.count++;

  // Check if we should suggest compact
  if (counter.count >= COMPACT_THRESHOLD) {
    const callsSinceReminder = counter.count - counter.lastReminder;

    if (callsSinceReminder >= COMPACT_REMINDER_INTERVAL) {
      counter.lastReminder = counter.count;
      saveCounter(counter);

      // Output suggestion (goes to stderr, visible in terminal)
      console.error('\n📦 COMPACT SUGGESTION');
      console.error(`   Tool calls: ${counter.count}`);
      console.error('   Consider running /compact at next logical boundary:');
      console.error('   - After completing current task');
      console.error('   - Before starting new feature');
      console.error('   - After brainstorming → planning transition\n');
      return;
    }
  }

  saveCounter(counter);
}

main();
