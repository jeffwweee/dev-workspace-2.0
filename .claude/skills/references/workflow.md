# Pichu Workflow Reference

Complete workflow for user messages in the Telegram system.

## Expected Workflow Flow

```
User message → Commander → Brainstorm → Confirm → Design → Plan → Background → Subagent → Review → Verify → Complete
                                       ↑               ↓           ↑            ↑           ↑
                                       └─── 3 retries ←─┘           └── Escalate ←─┘
```

## Phase 1: Message Processing (Commander)

1. **Parse message** - Extract TG_* values
2. **Read identity** - `state/memory/identity.md`
3. **ACK immediately** - Send contextual ack via `scripts/reply.sh`
4. **Detect intent** - Use `using-skill` to determine task type
5. **Execute** - Use appropriate workflow skill

## Phase 2: Design Phase (Brainstorming)

1. **Explore context** - Read files, docs, commits
2. **Ask questions** - One at a time, multiple choice preferred
3. **Propose approaches** - 2-3 options with trade-offs
4. **Present design** - Section-by-section approval
5. **Get explicit approval** - Wait for: "approved", "looks good", "yes proceed", "LGTM"
6. **Write design doc** - Save to `docs/plans/YYYY-MM-DD-<topic>-design.md`

## Phase 3: Planning Phase (Writing-Plans)

1. **Create implementation plan** - Break down into tasks
2. **Save plan** - `docs/plans/YYYY-MM-DD-<topic>-plan.md`
3. **Send for review** - Via `scripts/send-file.sh`
4. **Wait for approval** - User must approve execution

## Phase 4: Execution Phase (Background-Tasks)

1. **Load plan** - Read plan file
2. **Spawn subagent** - With `run_in_background: true`
3. **Track state** - Via `scripts/task-state.sh`
4. **Return to message loop** - Pichu stays responsive

## Phase 5: Subagent Execution (Subagent-Driven-Development)

For each task in plan:
```
Dispatch implementer → Spec review → Quality review → Verify → Mark complete
```

## Phase 6: Review (Reviewer)

Two-stage review:
1. **Spec Compliance** - Did we build what was asked?
2. **Code Quality** - Is it well-built?
3. **Confidence Score** - Rate 1-10, ≥8 to pass

## Failure Handling

### Review Failure Loop

```
Review fails → Spawn fix subagent → Re-review
     ↑                              ↓
     └────────── Max 3 times ────────┘
                    ↓
              Escalate to user
```

### Escalation Triggers

- 3 consecutive task failures
- Fix subagent fails 3 times
- Critical errors (auth failures, missing dependencies)

### Escalation Message Format

```
"Task failed after 3 attempts: [error summary]
Options:
- Modify plan
- Cancel
- Try different approach?"
```

### Escalation Loop-Back

If user selects "Try different approach" after escalation:
1. Invoke `brainstorming` skill with context from failure
2. Explore alternative approaches (different from original)
3. Get new design approval
4. Create updated implementation plan
5. Execute fresh background task (reset retry count)

## Task States

| State | Description | Transition |
|-------|-------------|------------|
| running | Active execution | Start task |
| completed | All criteria met | Verification passes |
| failed | Max retries exceeded | Escalate to user |

## Task Completion Criteria

A task is complete when:
- All sub-tasks completed
- All verifications passed
- No open review issues
- Confirmation of success

## Skill Integration

| Skill | Phase | Purpose |
|-------|-------|---------|
| commander | 1 | Message processing |
| brainstorming | 2 | Design exploration |
| writing-plans | 3 | Implementation planning |
| background-tasks | 4 | Background execution |
| subagent-driven-development | 5 | Task execution |
| reviewer | 6 | Quality assurance |
| verification-before-completion | 5 | Success confirmation |
