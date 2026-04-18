#!/bin/bash

# This script sets up the dotfiles by creating symbolic links to the correct locations.

# Exit immediately if a command exits with a non-zero status.
set -e

# Find the absolute path of the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
DEST_HOME="$HOME"
DEST_CONFIG="$HOME/.config"
DEST_OMZ="$HOME/.oh-my-zsh"

# Function to create a symlink, backing up the original file if it exists
create_symlink() {
    local source_path=$1
    local dest_path=$2
    local dest_dir=$(dirname "$dest_path")

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_dir"

    # If destination exists, back it up
    if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
        echo "Backing up existing $dest_path to $dest_path.bak"
        mv "$dest_path" "$dest_path.bak"
    fi

    echo "Symlinking $source_path to $dest_path"
    ln -s "$source_path" "$dest_path"
}

echo "Starting dotfiles setup..."

# --- Core Config Symlinks ---
create_symlink "$SCRIPT_DIR/.tmux.conf" "$DEST_HOME/.tmux.conf"
create_symlink "$SCRIPT_DIR/zsh/.zshrc" "$DEST_HOME/.zshrc"

# --- .config Folder Symlinks ---
echo "Ensuring $DEST_CONFIG exists..."
mkdir -p "$DEST_CONFIG"
create_symlink "$SCRIPT_DIR/nvim" "$DEST_CONFIG/nvim"
create_symlink "$SCRIPT_DIR/ghostty" "$DEST_CONFIG/ghostty"

# --- Oh My Zsh Setup ---
if [ ! -d "$DEST_OMZ" ]; then
    echo "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed."
fi

# --- Oh My Zsh Custom Folder Symlink ---
# Note: The default Oh My Zsh installation creates a 'custom' directory.
# We back it up and link our custom folder.
create_symlink "$SCRIPT_DIR/zsh/custom" "$DEST_OMZ/custom"


echo "✅ Dotfiles setup complete!"
echo "Please restart your terminal session for all changes to take effect."

