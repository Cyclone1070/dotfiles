#!/bin/sh
# This script attaches to a tmux session and silences its output on detach.

if tmux has-session 2>/dev/null; then
  # Redirect stdout and stderr to /dev/null
  tmux attach-session -t default >/dev/null 2>&1
else
  # Also redirect here
  tmux new-session -s default >/dev/null 2>&1
fi

# Fallback to a shell if tmux server is killed
exec "$SHELL" -l
