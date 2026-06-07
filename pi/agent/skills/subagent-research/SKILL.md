---
name: subagent-research
description: Offload verbose research (web, code, files, GitHub, video) to a subagent instead of burning main context window.
---

# Subagent Research

**Golden rule:** if the answer could be longer than 3 lines, use a subagent.

## Core Pattern

1. Identify the research need
2. Pick the right tool (see table below)
3. Craft 1-4 specific questions
4. Dispatch a `default` subagent with questions + brevity instruction
5. Subagent runs research in its own context, returns terse answers

## Template

```
Answer these questions as concisely as possible (one sentence per question):
1. [precise question]
2. [precise question]
No summarisation needed. Use [tool].
```

## When NOT to Use

- **Single fact** — "What year was Python 3.12?" → tool directly
- **Already know the query, answer is short** → inline
- **Need answer to proceed** → no subagent overhead
- **Trivial file lookup** — `grep` inline

## Research Types

| Type | Tool | Example question |
|------|------|-----------------|
| Web / general | `web_search` | "What are the pros/cons of X vs Y?" |
| Code / library internals | `code_search` | "What's the signature of React.useCallback?" |
| GitHub repos | `fetch_content` | "What does the README say about installation?" |
| YouTube / video | `fetch_content` + `prompt` | Pass user's exact question as prompt |
| File / workspace | `bash` (grep/find), `read` | "Where is DB configured in this project?" |
| Complex / multi-tool | combination | "Look up lib docs + check usage in codebase" |

## Common Mistakes

- Vague questions → rambling answers. Be specific.
- No brevity instruction → subagent defaults to verbose synthesis
- 5+ questions → split into multiple subagent calls
- Wrong tool for the type → `web_search` for code questions misses signatures
- `web_search` on main agent → do it in a subagent instead
