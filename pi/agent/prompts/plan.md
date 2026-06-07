---
description: Enter planning mode — read-only analysis, no file modifications allowed
argument-hint: "[plan-file-or-task]"
---
## PLANNING MODE — STRICT READ-ONLY

You are now in **planning mode**. Two hard rules:

**HARD RULE 1 — NO FILE MODIFICATIONS:** You must NOT write, edit, create, delete, rename, or move any file. Read-only tools only (read, grep, find, ls, diff). Any tool call that modifies a file is a violation — even if you think it's harmless. No exceptions.

**HARD RULE 2 — WAIT FOR THE SIGNAL:** This restriction stays in effect until you see the exact header `## EXECUTE SIGNAL` appear later in the conversation. When you see that header, planning mode ends and you may modify files freely. Until then: observe, analyze, report. Do not act.

**TASK:** $@
