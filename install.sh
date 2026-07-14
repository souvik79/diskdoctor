#!/bin/bash
# Disk Doctor installer (macOS). Deploys the scripts and schedules a monthly run.
set -e
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/.disk-doctor"
AGENT="$HOME/Library/LaunchAgents/com.diskdoctor.plist"
LABEL="com.diskdoctor"

echo "Installing Disk Doctor..."
mkdir -p "$DEST" "$HOME/DiskReports" "$HOME/Library/LaunchAgents"

# 1) deploy scripts
cp "$REPO_DIR/scan.sh" "$REPO_DIR/run.sh" "$DEST/"
chmod +x "$DEST/scan.sh" "$DEST/run.sh"

# 2) generate the launchd plist from the template (substitute $HOME)
sed "s|__HOME__|$HOME|g" "$REPO_DIR/com.diskdoctor.plist.template" > "$AGENT"

# 3) (re)load the schedule
launchctl unload "$AGENT" 2>/dev/null || true
launchctl load "$AGENT"

echo "✓ Installed."
echo "  Scripts : $DEST/{scan.sh,run.sh}"
echo "  Schedule: $AGENT  (1st of each month, 10:00)"
echo "  Reports : $HOME/DiskReports/disk-report-YYYY-MM.html"
echo
echo "Run once now to generate a report:"
echo "  bash $DEST/run.sh"
echo
if ! command -v claude >/dev/null 2>&1; then
  echo "NOTE: the 'claude' CLI was not found on PATH. Disk Doctor will still run and"
  echo "      produce a raw HTML report, but the AI-categorized version needs Claude Code:"
  echo "      https://claude.com/claude-code"
fi
