#!/usr/bin/env bash

# This is the core logic of the plugin.
# It's what runs when the key is pressed.
_fzf_windows_run() {
    # Check if fzf is installed
    if ! command -v fzf &> /dev/null; then
        tmux display-message "fzf not found. Please install fzf to use this plugin."
        exit 1
    fi

    local windows
    windows=$(tmux list-windows -F '#{window_name}')

    local selection
    selection=$(echo "$windows" | fzf --print-query --reverse --preview 'tmux capture-pane -ep -t {}' | tail -1)

    if [ -z "$selection" ]; then
        return
    fi

    if tmux list-windows -F '#{window_name}' | grep -q "^${selection}$"; then
        tmux select-window -t ":${selection}"
    else
        tmux new-window -n "$selection"
    fi
}

# This is the main entry point of the script.
main() {
    # CASE 1: The script is called with the argument "run".
    # This happens when the keybinding is triggered.
    if [ "$1" = "run" ]; then
        _fzf_windows_run
        return
    fi

    # CASE 2: The script is sourced by TPM at tmux startup.
    # No arguments are passed, so we set the keybinding here.
    # This makes the plugin self-binding and opinionated.
    # We must use -E to keep the popup open for the interactive fzf command.
    tmux bind-key s display-popup -w 80% -h 80% -b rounded -E "bash ~/.tmux/plugins/fzf-windows/fzf-windows.tmux run"
}

# Execute the main function, passing along any arguments.
main "$@"
