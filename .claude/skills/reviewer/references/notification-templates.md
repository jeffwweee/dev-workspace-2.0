# Notification Templates

## Ready to Commit (All Pass)

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "✅ Done! {summary}

Confidence: {score}/10

Files changed: {files}

Ready to commit." $MSG_ID
```

## Needs Fixes (Spec or Quality Fail)

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "⚠️ Issues found:

{issues}

Spawning fix subagent..." $MSG_ID
```

## Needs Manual Review (Low Confidence)

```bash
~/dev-workspace-v2/scripts/reply.sh pichu $CHAT_ID "⚠️ Review complete but confidence is {score}/10.

Please review before committing:

{concerns}

Files: {files}" $MSG_ID
```

## Fix Subagent Template

When spawning fix subagent:

```
Task tool:
  subagent_type: general-purpose
  model: sonnet
  description: "Fix review issues"
  prompt: |
    Fix these issues found in review:

    {list of issues from review}

    Files to fix: {file paths}
  run_in_background: true
```
