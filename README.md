# 🩺 Disk Doctor

**A self-running monthly disk-space report for macOS that tells you what's safe to delete — and why.**

Instead of a raw `du` dump, Disk Doctor scans your disk once a month, sends the data through [Claude Code](https://claude.com/claude-code), and produces a clean, light/dark **HTML dashboard** that sorts everything into:

- 🟢 **Safe to delete** — regenerable caches, stale duplicate tool/extension versions, runaway log files, Downloads/Trash — each with its size and an exact copy-paste command, plus a **total reclaimable** number.
- 🟡 **Review** — large items that need a human decision.
- 🔴 **Keep** — active app data and projects.

It also tracks **month-over-month trend**, so you catch the *next* runaway log or ballooning cache early — before you're staring at "0 bytes available."

> **Report-only. It never deletes anything.** It hands you the commands; you stay in control.

---

## Why

A single misconfigured log channel or a pile of regenerable caches can quietly eat tens of gigabytes. By the time you notice, you're at 4 GB free and things are breaking. Disk Doctor turns "clean up my disk" from a panicked afternoon into a 2-minute monthly glance.

---

## What it looks at

| Category | Examples |
|---|---|
| Free space + **trend** | current free space vs. last month |
| Biggest folders / files | top of `~`, individual files > 100 MB |
| **Runaway logs** | `*.log` files > 20 MB (often safe to truncate) |
| Regenerable caches | `~/Library/Caches`, `~/.cache`, `~/.npm`, `~/.gradle/caches`, `~/.cargo` |
| **Stale duplicate versions** | old VS Code extension builds, old CLI version dirs (keeps the newest) |
| Heavy tooling | Docker disk image, Xcode simulators |
| Low-hanging fruit | `~/Downloads`, `~/.Trash` |

---

## Requirements

- **macOS** (uses `launchd` for scheduling and `osascript` for the notification).
- **[Claude Code](https://claude.com/claude-code) CLI** (`claude`) for the AI-categorized report.
  Without it, Disk Doctor still runs and produces a **raw** HTML report as a fallback.

---

## Install

```bash
git clone https://github.com/souvik79/diskdoctor.git
cd diskdoctor
./install.sh
```

That deploys the scripts to `~/.disk-doctor/`, creates `~/DiskReports/`, and schedules a
monthly run (**1st of each month, 10:00**) via a `launchd` agent.

### Run it once right now

```bash
bash ~/.disk-doctor/run.sh
```

The report opens at `~/DiskReports/disk-report-YYYY-MM.html` and you get a macOS notification.

---

## How it works

```
launchd (monthly)
      │
      ▼
  run.sh ──► scan.sh          gathers raw disk data → ~/.disk-doctor/scan-YYYY-MM.txt
      │
      ├─────► claude -p        AI-categorizes the raw data into a self-contained HTML dashboard
      │                        (falls back to a plain raw HTML report if `claude` isn't installed)
      │
      ├─────► perl extract     strips any stray prose/code-fences → clean <!doctype…</html>
      │
      └─────► osascript        “Disk Doctor — Free: X” notification
                               report saved to ~/DiskReports/disk-report-YYYY-MM.html
```

| File | Purpose |
|---|---|
| `scan.sh` | Collects the raw disk data (uses `$HOME`, no hardcoded paths). |
| `run.sh` | Orchestrates scan → AI analysis → HTML → notification. |
| `com.diskdoctor.plist.template` | `launchd` schedule; `install.sh` fills in your `$HOME`. |
| `install.sh` / `uninstall.sh` | Set up / tear down. |

---

## Customize

**Change the schedule** — edit `com.diskdoctor.plist.template` (or the installed
`~/Library/LaunchAgents/com.diskdoctor.plist`) and re-run `./install.sh`:

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Day</key><integer>1</integer>   <!-- day of month -->
    <key>Hour</key><integer>10</integer>
    <key>Minute</key><integer>0</integer>
</dict>
```

For a **weekly** run, replace `Day` with `Weekday` (0–7, where 0/7 = Sunday).

**Tune what it scans** — edit `scan.sh` (add paths, change size thresholds).
**Tune the report** — edit the `INSTR` prompt in `run.sh`.

---

## Privacy

The scan output and generated reports list **your private file paths**, so they are
**git-ignored** and never leave your machine. The AI analysis runs through your own
Claude Code CLI. Nothing is uploaded anywhere by this tool.

---

## Uninstall

```bash
./uninstall.sh
```

Removes the schedule and the deployed scripts. Your generated reports in
`~/DiskReports/` are kept (delete them manually if you want).

---

## License

MIT — see [LICENSE](LICENSE).
