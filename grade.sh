#!/usr/bin/env bash
set -u
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
fail=0
pass() { echo "PASS: $*"; }
bad() { echo "FAIL: $*"; fail=1; }

for f in README.md system-info.sh disk-check.sh network-check.sh logs/.gitkeep; do
  [[ -f "$f" ]] && pass "required file exists: $f" || bad "missing file: $f"
done
for f in system-info.sh disk-check.sh network-check.sh grade.sh; do
  bash -n "$f" && pass "bash syntax: $f" || bad "bash syntax error: $f"
  [[ -x "$f" ]] && pass "executable: $f" || bad "not executable: $f (run chmod +x *.sh)"
done
./system-info.sh | grep -q 'Hostname:' && pass "system info hostname output" || bad "system info output"
./disk-check.sh 101 >/dev/null 2>&1; rc=$?
[[ $rc -eq 2 ]] && pass "disk threshold validation" || bad "disk threshold should return 2 (got $rc)"
./disk-check.sh abc >/dev/null 2>&1; rc=$?
[[ $rc -eq 2 ]] && pass "disk nonnumeric threshold validation" || bad "nonnumeric threshold should return 2 (got $rc)"
./network-check.sh >/dev/null 2>&1; rc=$?
[[ $rc -ne 0 ]] && pass "network missing-argument validation" || bad "network missing host should fail"
./network-check.sh example.com 70000 >/dev/null 2>&1; rc=$?
[[ $rc -eq 2 ]] && pass "network port range validation" || bad "invalid port should return 2 (got $rc)"
[[ -f logs/assignment-1.log ]] && pass "logging file created" || bad "expected log file was not created"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commits="$(git rev-list --count HEAD 2>/dev/null || echo 0)"
  [[ "$commits" -ge 5 ]] && pass "at least five Git commits ($commits)" || echo "WARN: only $commits commits; make at least five meaningful commits before submission"
  git branch --list | grep -qvE '^[* ]*(main|master)$' && pass "feature branch exists" || echo "WARN: create a feature branch and merge it into main"
else
  echo "WARN: not a Git repository yet; Git history checks skipped"
fi
if [[ $fail -eq 0 ]]; then echo "Assignment 1 local checks completed."; else echo "Assignment 1 checks failed."; fi
exit "$fail"
