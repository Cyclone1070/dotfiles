#!/usr/bin/env bash

# A script to interactively select a window with fzf and join it into a new split pane.

# Guard clause: Must be inside a tmux session.
if [[ -z "$TMUX" ]]; then
  exit 1
fi

# Determine split direction from the first argument
split_direction="$1"
split_flag=""

if [[ "$split_direction" == "vertical" ]]; then
  split_flag="-v"
elif [[ "$split_direction" == "horizontal" ]]; then
  split_flag="-h"
else
  tmux display-message "Error: Invalid argument to tmux-split.sh. Use 'vertical' or 'horizontal'. Received '$split_direction'."
  exit 1
fi

# Get the name of the current window to exclude it from the list.
current_window
current_window=$(tmux display-message -p '#W')

# Get a list of all windows, excluding the current one.
available_windows
available_windows=$(tmux list-windows -F '#W' | grep -v "^${current_window}$")

# If there are no other windows to join, exit gracefully.
if [[ -z "$available_windows" ]]; then
  tmux display-message "No other windows to join."
  exit 0
fi

# --- Floating FZF with Live Preview ---
tmp_file
tmp_file=$(mktemp) || exit 1
trap "rm -f '$tmp_file'" EXIT # Ensure temp file is cleaned up

# The preview command captures the content of the selected window with colors.
fzf_preview_command="tmux capture-pane -ep -t ':{}'"

# Define fzf options for the best experience.
fzf_options=(
  "--height 100%"
  "--layout=reverse"
  "--header 'Select a window to join'"
  "--preview \"$fzf_preview_command\""
  "--preview-window 'right:60%:border-rounded'"
)

# Run fzf inside a styled tmux popup.
tmux display-popup -w 80% -h 80% -b rounded -E "echo \"$available_windows\" | fzf ${fzf_options[*]} > \"$tmp_file\""

# Read the selection back from the temp file.
target_window
target_window=$(cat "$tmp_file")

# If the user cancelled fzf (e.g., pressed Esc), abort.
if [[ -z "$target_window" ]]; then
  exit 0
fi

# --- Logic Execution ---

# "Default" Window Safety Net
joining_default=false
if [[ "$target_window" == "default" ]]; then
  joining_default=true
fi

# Use join-pane, which both splits and moves the source pane.
tmux join-pane "$split_flag" -s ":$target_window"

# Recreate 'default' if it was just joined
if [[ "$joining_default" == true ]]; then
  tmux new-window -d -t :0 -n "default"
fi
