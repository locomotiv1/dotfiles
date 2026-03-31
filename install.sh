#!/bin/bash

# Get the absolute path to the dotfiles directory
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting Dotfiles Installation...${NC}\n"

# --- Package Manager Detection ---
if command -v pacman &>/dev/null; then
  PKG_MANAGER="pacman"
  INSTALL_CMD="sudo pacman -S --needed --noconfirm"
  UPDATE_CMD="sudo pacman -Sy"
elif command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
  INSTALL_CMD="sudo dnf install -y"
  UPDATE_CMD="sudo dnf makecache"
elif command -v apt-get &>/dev/null; then
  PKG_MANAGER="apt"
  INSTALL_CMD="sudo apt-get install -y"
  UPDATE_CMD="sudo apt-get update"
else
  echo -e "${RED}Error: Supported package manager (pacman, dnf, apt) not found. Please install packages manually.${NC}"
  exit 1
fi

echo -e "Detected package manager: ${YELLOW}$PKG_MANAGER${NC}"
$UPDATE_CMD

# --- Helper Functions ---

# Function to ask a yes/no question
ask() {
  while true; do
    read -p "$1 [Y/n] " yn
    case $yn in
    [Yy]*) return 0 ;;
    [Nn]*) return 1 ;;
    "") return 0 ;; # Default to Yes
    *) echo "Please answer yes or no." ;;
    esac
  done
}

# Function to symlink directories safely
link_config() {
  local source_dir="$DOTFILES_DIR/$1"
  local target_dir="$CONFIG_DIR/$1"

  if [ ! -d "$source_dir" ]; then
    echo -e "${RED}Warning: Source directory $source_dir does not exist. Skipping.${NC}"
    return
  fi

  mkdir -p "$CONFIG_DIR"

  if [ -e "$target_dir" ] || [ -L "$target_dir" ]; then
    echo -e "${YELLOW}Backing up existing $target_dir to $target_dir.bak${NC}"
    mv "$target_dir" "${target_dir}.bak"
  fi

  ln -sf "$source_dir" "$target_dir"
  echo -e "${GREEN}Symlinked $1 -> $target_dir${NC}"
}

# --- Module Installations ---

# 1. MPV
if ask "Install and configure mpv (Video Player)?"; then
  echo -e "${BLUE}Installing mpv and dependencies...${NC}"
  if [ "$PKG_MANAGER" == "pacman" ]; then
    $INSTALL_CMD mpv python lua yt-dlp
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    $INSTALL_CMD mpv python3 python3-pip lua yt-dlp
  else
    $INSTALL_CMD mpv python3 python3-pip lua5.3 yt-dlp
  fi

  # Optional: Python requests for mpv-mal-updater
  echo "Setting up Python environment for mpv MAL updater script..."
  pip install requests --user --break-system-packages 2>/dev/null || pip install requests --user

  link_config "mpv"
fi

# 2. Neovim (LazyVim requires specific dependencies)
if ask "Install and configure Neovim (LazyVim)?"; then
  echo -e "${BLUE}Installing Neovim and dependencies (ripgrep, fd, nodejs, gcc, etc.)...${NC}"
  if [ "$PKG_MANAGER" == "pacman" ]; then
    $INSTALL_CMD neovim git base-devel ripgrep fd npm xclip python unzip
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    $INSTALL_CMD neovim git gcc gcc-c++ make ripgrep fd-find nodejs xclip python3 unzip
  else
    $INSTALL_CMD neovim git build-essential ripgrep fd-find npm xclip python3 unzip
    # Link fd-find to fd on Debian/Ubuntu
    mkdir -p ~/.local/bin
    ln -sf $(which fdfind) ~/.local/bin/fd 2>/dev/null
  fi
  link_config "nvim"
fi

# 3. i3 Window Manager
if ask "Install and configure i3 Window Manager?"; then
  echo -e "${BLUE}Installing i3 and dependencies...${NC}"
  if [ "$PKG_MANAGER" == "pacman" ]; then
    $INSTALL_CMD i3-wm i3status i3lock xorg-xprop
  elif [ "$PKG_MANAGER" == "dnf" ]; then
    $INSTALL_CMD i3 i3status i3lock xprop
  else
    $INSTALL_CMD i3 i3status i3lock x11-utils
  fi
  link_config "i3"
fi

# 4. Awesome Window Manager
if ask "Install and configure Awesome Window Manager?"; then
  echo -e "${BLUE}Installing Awesome WM...${NC}"
  $INSTALL_CMD awesome
  link_config "awesome"
fi

# 5. Alacritty
if ask "Install and configure Alacritty (Terminal)?"; then
  echo -e "${BLUE}Installing Alacritty...${NC}"
  $INSTALL_CMD alacritty
  link_config "alacritty"
fi

# 6. Rofi
if ask "Install and configure Rofi (App Launcher)?"; then
  echo -e "${BLUE}Installing Rofi...${NC}"
  $INSTALL_CMD rofi
  link_config "rofi"
fi

# 7. Dunst
if ask "Install and configure Dunst (Notification Daemon)?"; then
  echo -e "${BLUE}Installing Dunst...${NC}"
  if [ "$PKG_MANAGER" == "pacman" ] || [ "$PKG_MANAGER" == "dnf" ]; then
    $INSTALL_CMD dunst libnotify
  else
    $INSTALL_CMD dunst libnotify-bin
  fi
  link_config "dunst"
fi

# 8. Custom Scripts
if ask "Install Custom Scripts (~/.local/bin)?"; then
  echo -e "${BLUE}Setting up scripts...${NC}"
  mkdir -p "$HOME/.local/bin"

  # Dependency for icon_workspaces.py
  echo "Installing Python dependencies for scripts..."
  pip install i3ipc --user --break-system-packages 2>/dev/null || pip install i3ipc --user

  # Install scrot/maim/brightnessctl often used in bash scripts
  $INSTALL_CMD maim xclip brightnessctl jq

  # Link scripts
  for script in "$DOTFILES_DIR/scripts/"*; do
    if [ -f "$script" ]; then
      filename=$(basename "$script")
      ln -sf "$script" "$HOME/.local/bin/$filename"
      chmod +x "$HOME/.local/bin/$filename"
      echo -e "Linked and made executable: $filename"
    fi
  done
  echo -e "${GREEN}Scripts installed to ~/.local/bin. Ensure this is in your \$PATH!${NC}"
fi

echo -e "\n${GREEN}Installation Complete!${NC}"
echo -e "Please log out and log back in, or restart your terminal/WM to see all changes."
