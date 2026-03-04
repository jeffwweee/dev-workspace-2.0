# Brainstorming Flow

## Detailed Steps

### 1. Explore Project Context

- Read relevant files in the codebase
- Check existing docs and README
- Review recent commits for patterns
- Load project-status.md via /memory if needed

### 2. Ask Clarifying Questions

**Rules:**
- One question per message
- Multiple choice preferred (easier to answer)
- Focus on: purpose, constraints, success criteria

**Example topics:**
- What problem does this solve?
- Who are the users?
- What are the constraints (time, complexity, tech stack)?
- What does success look like?

### 3. Propose Approaches

**Always present 2-3 options:**

| Approach | Description | Trade-offs |
|----------|-------------|------------|
| **Recommended:** Option A | Your top choice | Why it's best |
| Option B | Alternative | When to use this |
| Option C | Alternative | When to use this |

Lead with your recommendation and explain why.

### 4. Present Design Section-by-Section

**Cover:**
- Architecture (high-level)
- Components (what pieces)
- Data flow (how pieces connect)
- Error handling (edge cases)
- Testing (how we verify)

**Get approval after each section:**
- "Does this architecture look right?"
- "Any changes to the components?"

### 5. Write Design Doc

- Use template from `design-template.md`
- Save to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit to git

### 6. Get Final Approval

- Send design doc via send-file.sh
- Wait for user response
- If approved: invoke writing-plans skill
- If changes needed: revise and resend

## Next Skill

After design approved → **ONLY** invoke `writing-plans` skill.

Do NOT invoke any implementation skills directly.
