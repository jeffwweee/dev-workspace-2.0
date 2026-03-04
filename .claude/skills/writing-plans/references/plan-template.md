# Implementation Plan Template

Copy this structure for all plans:

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use `background-tasks` to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Context:** [Relevant files, patterns, architecture notes for unfamiliar subagent]

---

## Task 1: [Component Name]

**Files:**
- Create: `path/to/new/file.ts`
- Modify: `path/to/existing.ts:123-145`
- Test: `tests/path/to/test.ts`

**Changes:**
- [ ] Write failing test for X
- [ ] Implement X with Y behavior
- [ ] Run tests to verify pass
- [ ] Commit: "feat: add X feature"

**Code:**

```typescript
// Complete implementation code here
export function feature() {
  // ...
}
```

## Task 2: [Component Name]

...
```

## Notes

- Each task should be completable in 5-10 minutes
- Include exact file paths and line numbers
- Provide complete code snippets
- Specify test commands and expected output
- Reference memory files when needed: `state/memory/coding-standards.md`
- **Before saving:** Verify plan has complete context for unfamiliar subagent
