---
name: web-research-via-subagent
description: Use when the main agent needs to look up information on the web and wants to conserve context by offloading research to a subagent
---

# Web Research via Subagent

## Overview

**Subagent context is cheap; main agent context is precious.**

Web searches produce voluminous results — AI-synthesised answers, fetched page content, result listings. Running these through the main agent burns precious context window. Offloading web research to a `default` subagent lets it consume as many tokens as needed while the main agent focuses on the primary task.

## When to Use

- You need to look up multiple facts, compare options, or investigate a topic
- The research questions are well-defined but results may be lengthy
- You want to keep the main agent's context focused on the primary task

## When NOT to Use

- **Single factual query** — "What year was Python 3.12 released?" Use `web_search` directly.
- **Already have the right search terms** — if you know exactly what to query and the answer is short, do it inline.
- **Answer needed before subagent can return** — subagent overhead (dispatch + execution) costs time.
- **Question about library internals / open-source code** — use the `librarian` skill directly instead.

## Core Pattern

1. Identify the research need — what exactly do you need to know?
2. Craft 1–4 clean, specific questions. Each targets exactly what you need, no broader.
3. Dispatch a `default` subagent with the task to answer those questions using `web_search`.
4. Instruct the subagent to reply with the **briefest possible answers**: one sentence per question or a minimal bullet list. No intros, no conclusions, no commentary.

## Template

```
Answer these questions as concisely as possible (one sentence per question):
1. [precise question]
2. [precise question]
No summarisation needed.
```

## Example

**Need:** Choosing between two React state management libraries.

**Bad subagent task:**
> Research Zustand vs Jotai for me and tell me what you think.

**Good subagent task:**
> Answer these questions as concisely as possible (one sentence per question):
> 1. What are the bundle size differences between Zustand and Jotai?
> 2. Does either library have built-in support for persistence/middleware?
> 3. How do their re-render behaviours differ?
> No summarisation needed.

## Common Mistakes

- **Vague questions** — "Tell me about X" produces rambling. Ask what you actually need to know.
- **Omitting brevity instruction** — Without "one sentence per question" the subagent will default to verbose synthesis, defeating the purpose.
- **Too many questions** — 5+ questions produces a wall of text. Split into multiple subagent calls if needed.
- **Using the wrong tool** — `librarian` is for code/library internals (`code_search`). General web research uses `web_search`.
- **Subagent-ising trivial lookups** — a one-word answer doesn't justify dispatch overhead.
