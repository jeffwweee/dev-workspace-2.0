# Verification Examples

## Tests

```bash
# ✅ CORRECT
npm test
# Output: 34 passing, 0 failing
"✅ All 34 tests pass"

# ❌ WRONG
"Tests should pass now"
"Looks good to me"
```

## Linter

```bash
# ✅ CORRECT
npm run lint
# Output: No errors found
"✅ Linter clean (0 errors)"

# ❌ WRONG
"Linter passed" (without running it)
"Code looks clean"
```

## Build

```bash
# ✅ CORRECT
npm run build
# Output: Build succeeded (exit 0)
"✅ Build passes"

# ❌ WRONG
"Linter passed so build should work"
"Compiled successfully" (without running build)
```

## Bug Fix

```bash
# ✅ CORRECT
# Test original symptom
npm test -- --grep "original bug symptom"
# Output: 1 passing
"✅ Bug fixed - symptom test passes"

# ❌ WRONG
"Fixed the code, bug should be gone"
"Changed the logic, assumes fixed"
```

## Regression Tests (TDD Red-Green)

```bash
# ✅ CORRECT
# 1. Write test
# 2. Run test → PASS (green)
# 3. Revert fix
# 4. Run test → MUST FAIL (red)
# 5. Restore fix
# 6. Run test → PASS (green)
"✅ Regression test verified (red-green cycle confirmed)"

# ❌ WRONG
"Wrote a regression test" (without red-green verification)
```

## Requirements

```bash
# ✅ CORRECT
# 1. Re-read plan
# 2. Create checklist
# 3. Verify each requirement
# 4. Report completion OR gaps
"✅ All 5 requirements met:
   - [x] Req 1: ...
   - [x] Req 2: ...
   ..."

# ❌ WRONG
"Tests pass, so requirements must be met"
"Phase complete" (without verification)
```

## Agent Delegation

```bash
# ✅ CORRECT
# 1. Agent reports success
# 2. Check git diff
# 3. Verify changes match request
# 4. Report actual state
"✅ Agent completed:
   - Files changed: X, Y, Z
   - Verified: all requirements present"

# ❌ WRONG
"Agent said it worked"
"Subagent finished successfully"
```
