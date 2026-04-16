#!/usr/bin/env bash
# brew-import.sh — install Homebrew packages + SDKMAN candidates from a brew-export.sh snapshot
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

# Warn once up front if tools are missing, so the loops stay clean
if ! command -v brew &>/dev/null; then
  warn "brew not installed — Homebrew packages will be skipped. Install from https://brew.sh"
fi
if ! command -v mas &>/dev/null; then
  warn "mas not installed — App Store apps will be skipped. Install with: brew install mas"
fi

# ── Cache installed package lists once before the loop ───────────────────────
# Avoids spawning brew/mas per-package and prevents set -e from firing on
# grep returning 1 (no match) mid-loop.
_brew_taps=""
_brew_formulae=""
_brew_casks=""
_mas_list=""
if command -v brew &>/dev/null; then
  _brew_taps=$(brew tap 2>/dev/null || true)
  _brew_formulae=$(brew list --formula 2>/dev/null || true)
  _brew_casks=$(brew list --cask 2>/dev/null || true)
fi
if command -v mas &>/dev/null; then
  _mas_list=$(mas list 2>/dev/null || true)
fi

# ── SDKMAN bootstrap ─────────────────────────────────────────────────────────
_sdkman_loaded=false

_load_sdkman() {
  if $_sdkman_loaded; then return 0; fi
  local init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$init" ]]; then
    set +u
    # shellcheck disable=SC1090
    source "$init"
    set -u
    _sdkman_loaded=true
    return 0
  fi
  return 1
}

_ensure_sdkman() {
  if _load_sdkman; then
    return 0
  fi
  info "SDKMAN not found. Installing..."
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    info "[dry-run] Would install SDKMAN"
    return 0
  fi
  curl -s "https://get.sdkman.io" | bash
  local init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
  if [[ -f "$init" ]]; then
    set +u
    # shellcheck disable=SC1090
    source "$init"
    set -u
    _sdkman_loaded=true
  else
    error "SDKMAN install appeared to succeed but init script not found at $init"
    return 1
  fi
}

# Wrapper to suppress -u for the duration of any sdk call, since SDKMAN's
# internal scripts reference variables that may be unbound in a bash context.
run_sdk() {
  set +u
  sdk "$@" < /dev/null
  local rc=$?
  set -u
  return $rc
}

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
declare -a sdk_defaults=()

while IFS= read -r line; do
  # Detect section headers first, before the comment filter
  case "$line" in
    "### TAPS ###")                  section="taps";     continue ;;
    "### FORMULAE ###")              section="formulae"; continue ;;
    "### CASKS ###")                 section="casks";    continue ;;
    "### MAS (Mac App Store) ###")   section="mas";      continue ;;
    "### SDKMAN ###")                section="sdkman";   continue ;;
  esac

  # Skip comments and blanks — use if/then to avoid set -e firing on a false
  # [[ ]] && continue compound returning non-zero
  if [[ "$line" =~ ^[[:space:]]*# || -z "$line" ]]; then
    continue
  fi

  case "$section" in
    taps)
      if ! command -v brew &>/dev/null; then skipped=$((skipped + 1)); continue; fi
      already=$(echo "$_brew_taps" | grep -x "$line" || true)
      install_pkg "tap $line" "$already" brew tap "$line"
      # Refresh tap cache after a new tap is added
      if [[ -z "$already" && "$DRY_RUN" != "--dry-run" ]]; then
        _brew_taps=$(brew tap 2>/dev/null || true)
      fi
      ;;

    formulae)
      if ! command -v brew &>/dev/null; then skipped=$((skipped + 1)); continue; fi
      name="${line%% *}"
      already=$(echo "$_brew_formulae" | grep -x "$name" || true)
      install_pkg "$name" "$already" brew install "$name"
      ;;

    casks)
      if ! command -v brew &>/dev/null; then skipped=$((skipped + 1)); continue; fi
      name="${line%% *}"
      already=$(echo "$_brew_casks" | grep -x "$name" || true)
      install_pkg "$name" "$already" brew install --cask "$name"
      ;;

    mas)
      if ! command -v mas &>/dev/null; then skipped=$((skipped + 1)); continue; fi
      app_id="${line%% *}"
      app_name="${line#* }"
      already=$(echo "$_mas_list" | grep "^${app_id} " || true)
      install_pkg "$app_name" "$already" mas install "$app_id"
      ;;

    sdkman)
      candidate="${line%% *}"
      rest="${line#* }"
      version="${rest%% *}"
      is_default=""
      if [[ "$rest" == *" default"* || "$rest" == "default" ]]; then
        is_default="yes"
      fi

      if ! _ensure_sdkman; then
        warn "Skipping SDKMAN entry ($candidate $version) — SDKMAN unavailable"
        failed=$((failed + 1))
        continue
      fi

      SDKMAN_CANDIDATES_DIR="${SDKMAN_DIR:-$HOME/.sdkman}/candidates"
      already=""
      if [[ -d "$SDKMAN_CANDIDATES_DIR/$candidate/$version" ]]; then
        already="yes"
      fi

      install_pkg "sdk $candidate $version" "$already" run_sdk install "$candidate" "$version"

      if [[ -n "$is_default" ]]; then
        sdk_defaults+=("$candidate $version")
      fi
      ;;
  esac

done < "$INPUT_FILE"

# ── Apply SDKMAN defaults ────────────────────────────────────────────────────
if [[ ${#sdk_defaults[@]} -gt 0 ]]; then
  echo
  info "Applying SDKMAN defaults..."
  _load_sdkman || true
  for entry in "${sdk_defaults[@]}"; do
    candidate="${entry%% *}"
    version="${entry#* }"
    if [[ "$DRY_RUN" == "--dry-run" ]]; then
      info "[dry-run] Would run: sdk default $candidate $version"
    elif run_sdk default "$candidate" "$version"; then
      success "Set default: $candidate $version"
    else
      warn "Failed to set default for $candidate $version"
    fi
  done
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo
echo "────────────────────────────────"
if [[ "$DRY_RUN" == "--dry-run" ]]; then
  echo "Dry run complete — nothing was installed."
else
  echo "Import complete."
fi
echo -e "  ${GREEN}Installed:${NC} $installed"
echo -e "  ${CYAN}Skipped:${NC}   $skipped  (already present)"
echo -e "  ${RED}Failed:${NC}    $failed"
echo "────────────────────────────────"

if [[ $failed -gt 0 ]]; then exit 1; fi
exit 0