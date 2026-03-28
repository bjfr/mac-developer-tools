#!/usr/bin/env bash
# brew-export.sh — snapshot all installed Homebrew packages to a file
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

} > "$OUTPUT_FILE"

# Count what was captured
TAPS=$(brew tap | wc -l | tr -d ' ')
FORMULAE=$(brew leaves | wc -l | tr -d ' ')
CASKS=$(brew list --cask | wc -l | tr -d ' ')

echo ""
echo "Done."
echo "  Taps:      $TAPS"
echo "  Formulae:  $FORMULAE"
echo "  Casks:     $CASKS"
echo ""
echo "Transfer '$OUTPUT_FILE' to your new machine and run brew-import.sh"
