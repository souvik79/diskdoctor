#!/bin/bash
# Disk Doctor uninstaller (macOS). Removes the schedule and deployed scripts.
# Your generated reports in ~/DiskReports are kept (delete them manually if you want).
AGENT="$HOME/Library/LaunchAgents/com.diskdoctor.plist"

echo "Uninstalling Disk Doctor..."
launchctl unload "$AGENT" 2>/dev/null || true
rm -f "$AGENT"
rm -rf "$HOME/.disk-doctor"
echo "✓ Removed schedule and scripts."
echo "  Kept your reports in: $HOME/DiskReports  (delete manually if desired)"
