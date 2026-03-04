---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code. Creates implementation plans for background-tasks skill.
---

# Writing Plans

Write implementation plans for subagents to execute. Include context: files, patterns, architecture.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>-plan.md`

## Plan Review

Before saving, verify:
- [ ] All tasks have file paths
- [ ] Code is complete (not pseudocode)
- [ ] Commands are exact with expected output
- [ ] Context included (files, patterns, memory)

See `.claude/skills/writing-plans/references/plan-template.md` for template.

## Execution Handoff

See `.claude/skills/writing-plans/references/handoff-template.md` for handoff scripts.

## Guidelines

- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills with @ syntax
- DRY, YAGNI, TDD, frequent commits
