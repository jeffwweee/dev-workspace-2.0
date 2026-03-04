---
name: verification-before-completion
description: Required before ANY completion/fix/pass claim - must run verification command in current message and confirm output before asserting success
---

# Verification Before Completion

## Core Rule

**Evidence before claims. Always.**

No success assertions without fresh verification output in the current message.

## The Gate

Before ANY claim of completion/success/passing:
1. IDENTIFY: What command proves this?
2. RUN: Execute the FULL command (must be in current message)
3. READ: Full output, check exit code
4. VERIFY: Does output confirm the claim?
5. ONLY THEN: Make the claim

⚠️ STOP if: using "should"/"probably", expressing satisfaction before verification,
trusting agent reports, or relying on partial checks.

## When to Invoke

Before statements implying:
- Completion/done/finished
- Success/passing/fixed
- Readiness to commit/PR
- Moving to next task

## Required Evidence

| Claim | Must Show |
|-------|-----------|
| Tests pass | Test output with 0 failures |
| Linter clean | Linter output with 0 errors |
| Build succeeds | Build command exit code 0 |
| Bug fixed | Original symptom test passing |

See `references/examples.md` for verification patterns.
