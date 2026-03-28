#!/usr/bin/env bash
# brew-import.sh — install Homebrew packages from a brew-export.sh snapshot
set -euo pipefail

INPUT_FILE="${1:-brew-packages.txt}"
DRY_RUN="${2:-}"  # pass --dry-run as second arg to preview without installing

# Colour helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Verify input file
if [[ ! -f "$INPUT_FILE" ]]; then
  error "Package file '$INPUT_FILE' not found."
  echo "Usage: $0 [brew-packages.txt] [--dry-run]"
  exit 1
fi

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

# ── Parse and install ────────────────────────────────────────────────────────
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

done < "$INPUT_FILE"

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
