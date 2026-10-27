#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/assignment-1.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true
log() { printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }
usage() { echo "Usage: $0 <threshold: 1-100> [path]" >&2; }

if [[ $# -lt 1 || $# -gt 2 ]]; then usage; log "disk check rejected: wrong argument count"; exit 2; fi
threshold="$1"
path="${2:-/}"
if [[ ! "$threshold" =~ ^[0-9]+$ ]] || (( threshold < 1 || threshold > 100 )); then
  usage; log "disk check rejected: invalid threshold '$threshold'"; exit 2
fi
if [[ ! -e "$path" ]]; then
  echo "Error: path does not exist: $path" >&2; log "disk check failed: missing path '$path'"; exit 1
fi
usage_pct="$(df -P "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/, "", $5); print $5}')"
if [[ ! "$usage_pct" =~ ^[0-9]+$ ]]; then
  echo "Error: unable to determine disk usage for: $path" >&2; log "disk check failed: unable to read df output for '$path'"; exit 1
fi
printf 'Disk usage for %s: %s%% (threshold: %s%%)\n' "$path" "$usage_pct" "$threshold"
if (( usage_pct >= threshold )); then
  echo "WARNING: disk usage has reached or exceeded the threshold."
  log "disk check warning: path='$path' usage=${usage_pct}% threshold=${threshold}%"
  exit 1
fi
echo "OK: disk usage is below the threshold."
log "disk check passed: path='$path' usage=${usage_pct}% threshold=${threshold}%"
exit 0
