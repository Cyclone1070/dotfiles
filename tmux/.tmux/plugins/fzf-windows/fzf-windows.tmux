#!/usr/bin/env bash
# Check if fzf is installed
if ! command -v fzf &> /dev/null; then
    tmux display-message "fzf not found. Please install fzf to use fzf-twindows plugin."
    exit 1
fi

_fzf_windows_run() {
    # Get all window names in the current session, excluding the current one
    local windows
    windows=$(tmux list-windows -F '#{window_name}')

    # Use fzf to select or create a window
    local selection
    selection=$(echo "$windows" | fzf --print-query --reverse --preview 'tmux capture-pane -p -t {}' | tail -1)

    # Exit if fzf was cancelled (e.g., via Esc)
    if [ -z "$selection" ]; then
        return
    fi

    # Check if the selection exists as a window
    if tmux list-windows -F '#{window_name}' | grep -q "^${selection}$"; then
        # If it exists, switch to it
        tmux select-window -t ":${selection}"
    else
        # If it doesn't exist, create a new window with that name
        tmux new-window -n "$selection"
    fi
}

# This part allows the script to be sourced or run directly
if [ "$1" = "run" ]; then
    _fzf_windows_run
else
    # Expose a tmux command to run the fzf-twindows functionality
    # The user can bind this to a key in their .tmux.conf
    # Example: bind C-w run-shell "bash $TMUX_PLUGIN_DIR/fzf-twindows/fzf-twindows.tmux run"
    tmux bind-key w display-popup "bash ~/.tmux/plugins/fzf-windows/fzf-windows.tmux run"
fi
