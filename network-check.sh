#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/assignment-1.log"
mkdir -p "$LOG_DIR" 2>/dev/null || true
log() { printf '%s - %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }
usage() { echo "Usage: $0 <hostname-or-ip> [port]" >&2; }

if [[ $# -lt 1 || $# -gt 2 ]]; then usage; log "network check rejected: wrong argument count"; exit 2; fi
host="$1"
port="${2:-}"
# Conservative hostname/IP input validation; actual DNS resolution validates whether it exists.
if [[ -z "$host" || "$host" == -* || ! "$host" =~ ^[A-Za-z0-9._:-]+$ ]]; then
  echo "Error: invalid hostname or IP address." >&2; usage; log "network check rejected: invalid host '$host'"; exit 2
fi
if [[ -n "$port" ]] && { [[ ! "$port" =~ ^[0-9]+$ ]] || (( 10#$port < 1 || 10#$port > 65535 )); }; then
  echo "Error: port must be an integer from 1 to 65535." >&2; usage; log "network check rejected: invalid port '$port'"; exit 2
fi

echo "=== Network Check ==="
echo "Host: $host"
if command -v getent >/dev/null 2>&1; then
  resolved="$(getent ahosts "$host" 2>/dev/null | awk '!seen[$1]++ {print $1}' | paste -sd ', ' -)"
else
  resolved=""
fi
if [[ -n "$resolved" ]]; then
  echo "Resolved address(es): $resolved"
  log "resolved host '$host' to '$resolved'"
else
  echo "DNS/host resolution: FAILED"
  log "host resolution failed for '$host'"
  exit 1
fi

if command -v ping >/dev/null 2>&1; then
  if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
    echo "Basic connectivity (ICMP ping): reachable"
    log "ICMP ping succeeded for '$host'"
  else
    echo "Basic connectivity (ICMP ping): no response (ICMP may be blocked)"
    log "ICMP ping did not receive a response for '$host'"
  fi
else
  echo "Basic connectivity (ICMP ping): skipped (ping command unavailable)"
  log "ICMP ping skipped: command unavailable"
fi

echo "Network interfaces:"
if command -v ip >/dev/null 2>&1; then
  ip -brief address 2>/dev/null || ip address 2>/dev/null || true
else
  echo "Interface details unavailable (install iproute2 to enable this section)."
fi

if [[ -n "$port" ]]; then
  echo "TCP connectivity to ${host}:${port}:"
  if command -v nc >/dev/null 2>&1; then
    if nc -z -w 3 "$host" "$port" >/dev/null 2>&1; then
      echo "TCP port $port: OPEN"
      log "TCP connection succeeded for '$host:$port'"
    else
      echo "TCP port $port: CLOSED or unreachable"
      log "TCP connection failed for '$host:$port'"
      exit 1
    fi
  elif timeout 3 bash -c ":</dev/tcp/$host/$port" >/dev/null 2>&1; then
    echo "TCP port $port: OPEN"
    log "TCP connection succeeded using bash for '$host:$port'"
  else
    echo "TCP port $port: CLOSED, unreachable, or TCP check unavailable"
    log "TCP connection failed for '$host:$port'"
    exit 1
  fi
fi
log "network check completed for '$host'${port:+ port $port}"
