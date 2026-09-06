# Plan: Add communication-style rules to AGENTS.md

## Goal

Append three assistant-behavior rules to `AGENTS.md`:

1. Reply briefly, no fluff, no verbose reasoning.
2. Communicate in Russian.
3. When the user's question is ambiguous or lacks information — ask clarifying questions instead of guessing.

## File to change

`F:\My_VC_Projects\quran_app\AGENTS.md`

## Edit

Insert a new top-level section at the **top of the file**, right after
the `# Agent Instructions — quran_app` heading (so the rules are
discoverable first, before project-specific MCP / audio notes).

New section:

```markdown
## Assistant communication style

- **Be brief.** No filler, no verbose reasoning in the final reply.
- **Respond in Russian.** Match the user's language.
- **Ask when unclear.** If the user's request is ambiguous or missing
  information, ask clarifying questions instead of guessing.
```

## Verification

- `git diff AGENTS.md` shows only the inserted section.
- No other files touched.
- Heading hierarchy preserved (`#` → `##`).