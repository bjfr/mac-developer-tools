#!/usr/bin/env bash
# Self-importing Homebrew snapshot — run this file on a new machine to install
# Usage: ./brew-install.sh [--dry-run]
set -euo pipefail

DRY_RUN="${1:-}"

# Colour helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
  info "Homebrew not found. Installing..."
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    info "[dry-run] Would install Homebrew"
  else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # shellcheck disable=SC1091
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    command -v brew &>/dev/null || { error "brew still not found after install — check your architecture (ARM vs Intel)"; exit 1; }
  fi
fi

# Warn once up front if mas is missing, so the loop stays clean
if ! command -v mas &>/dev/null; then
  warn "mas not installed — App Store apps will be skipped. Install with: brew install mas"
fi

# Counters
installed=0; skipped=0; failed=0

# Install a single package, respecting dry-run mode and tracking the result
install_pkg() {
  local label="$1"; shift  # human-readable name for messages
  local already_installed="$1"; shift  # non-empty string = already present
  local cmd=("$@")  # the install command to run

  if [[ -n "$already_installed" ]]; then
    skipped=$((skipped + 1))
    return
  fi

  info "Installing $label..."
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    info "[dry-run] Would run: ${cmd[*]}"
    installed=$((installed + 1))
  elif "${cmd[@]}"; then
    success "Installed $label"
    installed=$((installed + 1))
  else
    warn "Failed to install $label"
    failed=$((failed + 1))
  fi
}

# ── Read the package list embedded at the bottom of this file ────────────────
section=""

while IFS= read -r line; do
  # Detect section headers first, before the comment filter
  case "$line" in
    "### TAPS ###")                  section="taps";     continue ;;
    "### FORMULAE ###")              section="formulae"; continue ;;
    "### CASKS ###")                 section="casks";    continue ;;
    "### MAS (Mac App Store) ###")   section="mas";      continue ;;
  esac

  # Skip comments and blanks
  [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

  case "$section" in
    taps)
      already=$(brew tap | grep -x "$line" || true)
      install_pkg "tap $line" "$already" brew tap "$line"
      ;;

    formulae)
      name="${line%% *}"
      already=$(brew list --formula 2>/dev/null | grep -x "$name" || true)
      install_pkg "$name" "$already" brew install "$name"
      ;;

    casks)
      name="${line%% *}"
      already=$(brew list --cask 2>/dev/null | grep -x "$name" || true)
      install_pkg "$name" "$already" brew install --cask "$name"
      ;;

    mas)
      command -v mas &>/dev/null || { skipped=$((skipped + 1)); continue; }
      app_id="${line%% *}"
      app_name="${line#* }"
      already=$(mas list 2>/dev/null | grep "^${app_id} " || true)
      install_pkg "$app_name" "$already" mas install "$app_id"
      ;;
  esac

done < <(sed -n '/^### PACKAGES ###$/,$ p' "$0" | tail -n +2)

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "────────────────────────────────"
[[ "$DRY_RUN" == "--dry-run" ]] && echo "Dry run complete — nothing was installed." || echo "Import complete."
echo -e "  ${GREEN}Installed:${NC} $installed"
echo -e "  ${CYAN}Skipped:${NC}   $skipped  (already present)"
echo -e "  ${RED}Failed:${NC}    $failed"
echo "────────────────────────────────"

[[ $failed -gt 0 ]] && exit 1
exit 0

### PACKAGES ###
# Generated on: Sat Mar 28 11:16:50 CET 2026
# Hostname: Bjorns-MacBook-Pro.local
# Homebrew version: Homebrew 5.1.1

### TAPS ###

### FORMULAE ###
# Plugin manager for zsh, inspired by antigen and antibody
antidote
# Official Amazon AWS command-line interface
awscli
# Microsoft Azure CLI 2.0
azure-cli
# Bourne-Again SHell, a UNIX command interpreter
bash
# Clone of cat(1) with syntax highlighting and Git integration
bat
# Cloudflare Tunnel client (formerly Argo Tunnel)
cloudflared
# Suite of command-line tools for converting to and working with CSV
csvkit
# Isolated development environments using Docker
docker-compose
# .NET Core
dotnet
# Modern, maintained replacement for ls
eza
# Test various flash cards
f3
# Simple, fast and user-friendly alternative to find
fd
# Command-line fuzzy finder written in Go
fzf
# Interact with Google Gemini AI models from the command-line
gemini-cli
# GitHub command-line tool
gh
# Distributed revision control system
git
# Open-source GitLab command-line tool
glab
# User-friendly cURL replacement (command-line HTTP client)
httpie
# Kubernetes command-line interface
kubernetes-cli
# Simple terminal UI for git commands
lazygit
# Conversion library
libiconv
# Mac App Store command-line interface
mas
# AI coding agent, built for the terminal
opencode
# Object-relational database system
postgresql@17
# Theme for zsh
powerlevel10k
# Persistent key-value database, with built-in net interface
redis
# Wrapper around ripgrep that adds multiple rich file types
ripgrep-all
# Modern reverse proxy
traefik
# Command-line interface to the freedesktop.org trashcan
trash-cli
# Display directories as trees (with optional color/HTML output)
tree
# Extremely fast Python package installer and resolver, written in Rust
uv
# Shell extension to navigate your filesystem faster
zoxide

### CASKS ###
# (Bitwarden) Desktop password and login vault
bitwarden
# (Claude) Anthropic's official Claude AI desktop app
claude
# (Claude Code) Terminal-based AI coding assistant
claude-code
# (DaisyDisk) Disk space visualiser
daisydisk
# (DBeaver Community Edition) Universal database tool and SQL client
dbeaver-community
# (Docker Desktop, Docker Community Edition, Docker CE) App to build and share containerised applications and microservice
docker-desktop
# (.NET SDK) Developer platform
dotnet-sdk
# (JetBrainsMono Nerd Font families (JetBrains Mono)) [no description]
font-jetbrains-mono-nerd-font
# (Google Cloud CLI) Set of tools to manage resources and applications hosted on Google Cloud
gcloud-cli
# (Google Chrome) Web browser
google-chrome
# (Google Drive) Client for the Google Drive storage service
google-drive
# (iTerm2) Terminal emulator as alternative to Apple's Terminal app
iterm2
# (JetBrains Toolbox) JetBrains tools manager
jetbrains-toolbox
# (KeePassXC) Password manager app
keepassxc
# (Maccy) Clipboard manager
maccy
# (Ollama) Get up and running with large language models locally
ollama-app
# (OpenCode) AI coding agent desktop client
opencode-desktop
# (OpenVPN Connect client) Client program for the OpenVPN Access Server
openvpn-connect
# (Rectangle) Move and resize windows using keyboard shortcuts or snap areas
rectangle
# (Redis Insight) GUI for streamlined Redis application development
redis-insight
# (Slack) Team communication and collaboration software
slack
# (Spotify) Music streaming service
spotify
# (Sweet Home 3D) Interior design application
sweet-home3d
# (Tunnelblick) Free and open-source OpenVPN client
tunnelblick
# (Microsoft Visual Studio Code, VS Code) Open-source code editor
visual-studio-code
# (WhatsApp) Native desktop client for WhatsApp
whatsapp

### MAS (Mac App Store) ###
