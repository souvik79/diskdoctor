#!/bin/bash
# Disk Doctor — gathers raw disk data for the monthly report.
# Usage: scan.sh <output-file>
STATE="$HOME/.disk-doctor"
mkdir -p "$STATE"
RAW="${1:-/tmp/disk-doctor-raw.txt}"

{
echo "# macOS Disk Scan — $(date '+%Y-%m-%d %H:%M')"
echo

echo "## Free space (whole disk)"
df -h / | awk 'NR==1||NR==2'
FREE_GB=$(df -g / | awk 'NR==2{print $4}')
echo "FreeGB_now=$FREE_GB"
if [ -f "$STATE/last_free_gb.txt" ]; then
  LAST=$(cat "$STATE/last_free_gb.txt")
  echo "FreeGB_last_month=$LAST  (delta_since_last=$((FREE_GB-LAST))GB)"
else
  echo "FreeGB_last_month=none (first run)"
fi
echo "$FREE_GB" > "$STATE/last_free_gb.txt"
echo

echo "## Top-level home folders (largest 20)"
du -sh "$HOME"/* 2>/dev/null | sort -rh | head -20
echo

echo "## Biggest individual files (>100MB, top 25)"
find "$HOME" -type f -size +100M 2>/dev/null -exec du -sh {} \; | sort -rh | head -25
echo

echo "## Runaway logs (*.log > 20MB) — usually safe to truncate"
find "$HOME" -type f -name '*.log' -size +20M 2>/dev/null -exec du -sh {} \; | sort -rh | head -15
echo

echo "## Regenerable caches"
du -sh "$HOME/Library/Caches" "$HOME/.cache" "$HOME/.npm" "$HOME/.gradle/caches" "$HOME/.cargo" 2>/dev/null | sort -rh
echo

echo "## Stale duplicate versions (keep newest of each)"
echo "claude-code ext versions:"; ls -1d "$HOME"/.vscode/extensions/anthropic.claude-code-* 2>/dev/null | sed 's|.*/||'
echo "chatgpt ext versions:";     ls -1d "$HOME"/.vscode/extensions/openai.chatgpt-* 2>/dev/null | sed 's|.*/||'
echo "standalone claude versions:"; ls -1 "$HOME/.local/share/claude/versions" 2>/dev/null
echo

echo "## Docker / Xcode simulators"
du -sh "$HOME/Library/Containers/com.docker.docker" 2>/dev/null
du -sh /Library/Developer/CoreSimulator 2>/dev/null
echo

echo "## Downloads & Trash"
du -sh "$HOME/Downloads" "$HOME/.Trash" 2>/dev/null
} > "$RAW" 2>&1

echo "$RAW"
