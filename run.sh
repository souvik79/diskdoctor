#!/bin/bash
# Disk Doctor — monthly: scan -> AI-analyze with headless Claude -> HTML report + notification.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
STATE="$HOME/.disk-doctor"
OUT="$HOME/DiskReports"
mkdir -p "$STATE" "$OUT"
MONTH="$(date '+%Y-%m')"
RAW="$STATE/scan-$MONTH.txt"
HTML="$OUT/disk-report-$MONTH.html"

# 1) gather data
bash "$STATE/scan.sh" "$RAW" >/dev/null 2>&1

# 2) AI analysis -> self-contained HTML dashboard (text in/out only; no tools, so no perm prompts)
INSTR="You are Disk Doctor, a macOS cleanup analyst. From the raw scan below, produce ONE self-contained, responsive HTML document (inline CSS only, NO external assets; support BOTH light and dark via prefers-color-scheme) titled 'Disk Doctor — $MONTH'. Sections:
1) Headline: current free space + month-over-month trend (use FreeGB_now vs FreeGB_last_month).
2) GREEN 'Safe to delete' table: regenerable caches, duplicate tool/extension versions (KEEP the newest of each, list the older ones), runaway *.log files (truncate), Downloads/Trash. Each row: item, size, and an exact copy-paste command (rm -rf / ': > file' for logs). Add a 'Total reclaimable' sum.
3) YELLOW 'Review' table: large files/folders needing a human decision.
4) RED 'Keep' notes: active app data / projects — do not delete.
Be strictly accurate to the data; never invent paths or sizes.
CRITICAL OUTPUT RULES: Do NOT write any file. Do NOT use tools. Do NOT add any explanation, preamble, or markdown code fences. Print ONLY the raw HTML to stdout, starting exactly with <!doctype html> and ending with </html>. RAW SCAN:
"
CLAUDE_BIN="$(command -v claude || echo "$HOME/.local/bin/claude")"
AI_OUT="$STATE/ai-out-$MONTH.txt"
"$CLAUDE_BIN" -p "$INSTR
$(cat "$RAW")" > "$AI_OUT" 2>"$STATE/last-run.log"

# Extract just the HTML document (strip any prose/code-fence Claude may add)
/usr/bin/perl -0777 -ne 'print $1 if /(<!doctype html\b.*?<\/html>)/is' "$AI_OUT" > "$HTML"

# 3) fallback if the AI step produced nothing usable
if [ ! -s "$HTML" ] || ! grep -qi "<" "$HTML"; then
  {
    echo "<!doctype html><meta charset=utf-8><title>Disk Doctor $MONTH (raw)</title>"
    echo "<style>body{font:14px -apple-system,sans-serif;max-width:900px;margin:2rem auto;padding:0 1rem}pre{background:#f4f4f5;padding:1rem;border-radius:8px;overflow:auto}@media(prefers-color-scheme:dark){body{background:#111;color:#eee}pre{background:#1c1c1e}}</style>"
    echo "<h1>🩺 Disk Doctor — $MONTH (raw fallback)</h1><p>AI step unavailable; showing raw scan.</p><pre>"
    sed 's/&/\&amp;/g; s/</\&lt;/g' "$RAW"
    echo "</pre>"
  } > "$HTML"
fi

# 4) notify
FREE="$(df -h / | awk 'NR==2{print $4}')"
/usr/bin/osascript -e "display notification \"Free: $FREE — report saved to ~/DiskReports\" with title \"🩺 Disk Doctor — $MONTH\" sound name \"Glass\"" 2>/dev/null

echo "$HTML"
