# Design Document Template

Save to: `docs/plans/YYYY-MM-DD-<topic>-design.md`

```markdown
# [Feature Name] Design

**Goal:** [One sentence]

**Date:** YYYY-MM-DD

---

## Overview

[2-3 sentences about what we're building and why]

## Approaches Considered

| Approach | Pros | Cons |
|----------|------|------|
| **Recommended:** [Name] | ... | ... |
| Alternative: [Name] | ... | ... |

## Architecture

[High-level architecture diagram or description]

## Components

| Component | Responsibility |
|-----------|---------------|
| [Name] | [What it does] |
| [Name] | [What it does] |

## Data Flow

1. User action → Component A
2. Component A → Component B
3. Component B → Database/Response

## Error Handling

- [Error case 1]: [How we handle it]
- [Error case 2]: [How we handle it]

## Testing Strategy

- Unit tests for [components]
- Integration tests for [flows]
- E2E tests for [critical paths]

## Open Questions

- [Question 1]
- [Question 2]

---

**Approved:** [User approval]
