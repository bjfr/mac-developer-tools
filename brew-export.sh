#!/usr/bin/env bash
# brew-export.sh — snapshot all installed Homebrew packages + SDKMAN candidates to a file
set -euo pipefail

OUTPUT_FILE="${1:-brew-packages.txt}"

# Verify Homebrew is available
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew not found. Install it from https://brew.sh" >&2
  exit 1
fi

echo "Exporting Homebrew packages to: $OUTPUT_FILE"

{
  echo "# Homebrew package export"
  echo "# Generated on: $(date)"
  echo "# Hostname: $(hostname)"
  echo "# Homebrew version: $(brew --version | head -1)"
  echo

  echo "### TAPS ###"
  brew tap
  echo

  echo "### FORMULAE ###"
  brew leaves
  echo

  echo "### CASKS ###"
  brew list --cask
  echo

  echo "### MAS (Mac App Store) ###"
  if command -v mas &>/dev/null; then
    mas list
  else
    echo "# mas not installed — Mac App Store apps not captured"
    echo "# Install with: brew install mas"
  fi
  echo

  echo "### SDKMAN ###"
  SDKMAN_CANDIDATES_DIR="${SDKMAN_CANDIDATES_DIR:-$HOME/.sdkman/candidates}"
  if [[ -d "$SDKMAN_CANDIDATES_DIR" ]]; then
    for candidate_dir in "$SDKMAN_CANDIDATES_DIR"/*/; do
      [[ -d "$candidate_dir" ]] || continue
      candidate=$(basename "$candidate_dir")

      # Resolve the default version via the 'current' symlink
      current_version=""
      if [[ -L "$candidate_dir/current" ]]; then
        current_version=$(basename "$(readlink "$candidate_dir/current")")
      fi

      for ver_dir in "$candidate_dir"*/; do
        [[ -d "$ver_dir" ]] || continue
        ver=$(basename "$ver_dir")
        [[ "$ver" == "current" ]] && continue

        if [[ "$ver" == "$current_version" ]]; then
          echo "$candidate $ver default"
        else
          echo "$candidate $ver"
        fi
      done
    done
  else
    echo "# SDKMAN not found at $SDKMAN_CANDIDATES_DIR — skipping"
  fi

} > "$OUTPUT_FILE"

# Count what was captured
TAPS=$(brew tap | wc -l | tr -d ' ')
FORMULAE=$(brew leaves | wc -l | tr -d ' ')
CASKS=$(brew list --cask | wc -l | tr -d ' ')
MAS_COUNT=0
if command -v mas &>/dev/null; then
  MAS_COUNT=$(mas list | wc -l | tr -d ' ')
fi
SDKMAN_CANDIDATES_DIR="${SDKMAN_CANDIDATES_DIR:-$HOME/.sdkman/candidates}"
SDK_COUNT=0
if [[ -d "$SDKMAN_CANDIDATES_DIR" ]]; then
  SDK_COUNT=$(grep -c '^[^#]' <(
    for d in "$SDKMAN_CANDIDATES_DIR"/*/; do
      for v in "$d"*/; do [[ -d "$v" && "$(basename "$v")" != "current" ]] && echo x; done
    done
  ) || true)
fi

echo ""
echo "Done."
echo "  Taps:            $TAPS"
echo "  Formulae:        $FORMULAE"
echo "  Casks:           $CASKS"
echo "  App Store apps:  $MAS_COUNT"
echo "  SDKMAN apps:     $SDK_COUNT"
echo ""
echo "Transfer '$OUTPUT_FILE' to your new machine and run brew-import.sh"