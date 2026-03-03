# Patterns

Reusable patterns discovered during development.

## Context Injection Pattern
When spawning subagents, inject full context in prompt:
- Task description
- Project context from memory
- Coding standards
- Session context (chat_id, user, recent messages)

## Silent Execution Pattern
Pichu never outputs to terminal - only communicates via /reply endpoint.

## Fresh Subagent Pattern
Never reuse subagents for multiple tasks. Each task gets a fresh agent with full context.
