#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/assignment-1.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true

log() {
  printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*" >> "$LOG_FILE" 2>/dev/null || true
}

read_os() {
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    printf '%s' "${PRETTY_NAME:-Unknown Linux}"
  else
    uname -s
  fi
}

printf '%s\n' "=== System Information ==="
printf 'Hostname: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
printf 'Current user: %s\n' "$(id -un 2>/dev/null || printf 'unknown')"
printf 'Date/time: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
printf 'Operating system: %s\n' "$(read_os)"
printf 'Kernel version: %s\n' "$(uname -r 2>/dev/null || printf 'unknown')"
printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime 2>/dev/null || printf 'unknown')"
printf 'CPU information:\n'
if [[ -r /proc/cpuinfo ]]; then
  grep -m 1 -E '^(model name|Hardware|Processor)[[:space:]]*:' /proc/cpuinfo 2>/dev/null || printf 'CPU details unavailable\n'
else
  printf 'CPU details unavailable\n'
fi
printf 'Memory information:\n'
if command -v free >/dev/null 2>&1; then
  free -h
elif [[ -r /proc/meminfo ]]; then
  head -n 5 /proc/meminfo
else
  printf 'Memory details unavailable\n'
fi
printf 'Current working directory: %s\n' "$PWD"
log "system information displayed for user $(id -un 2>/dev/null || printf unknown)"
