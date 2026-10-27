# Assignment 1 — Linux, Bash & Networking Diagnostic Toolkit

A small Linux diagnostic toolkit written in Bash. It collects runtime system information, checks filesystem usage against a threshold, performs hostname resolution and basic connectivity checks, and records operations in `logs/`.

## Requirements

- Linux (Ubuntu/WSL 2 recommended)
- Bash
- Standard Linux utilities: `hostname`, `date`, `uname`, `uptime`, `df`, `awk`, `grep`, `sed`, `getent`
- Optional network utilities: `ping`, `ip`, `nc` (the scripts degrade gracefully when some are unavailable)

## Project structure

```text
assignment-1/
├── README.md
├── system-info.sh
├── disk-check.sh
├── network-check.sh
├── grade.sh
└── logs/
    └── .gitkeep
```

## Setup

From the project directory:

```bash
chmod +x grade.sh system-info.sh disk-check.sh network-check.sh
mkdir -p logs
```

On Windows, use Ubuntu in WSL rather than running these scripts directly in PowerShell.

## Usage

### Display system information

```bash
./system-info.sh
```

Displays hostname, current user, date/time, OS, kernel, uptime, CPU, memory and current working directory. Values are read at runtime.

### Check disk usage

```bash
./disk-check.sh 80
./disk-check.sh 90 /var
```

- Syntax: `./disk-check.sh <threshold> [path]`
- Threshold must be an integer from 1 to 100.
- Path defaults to `/`.
- Exit `0` if usage is **below** the threshold.
- Exit `1` if usage is **equal to or above** the threshold or the operation fails.
- Exit `2` for invalid arguments.

### Check network

```bash
./network-check.sh example.com
./network-check.sh example.com 443
./network-check.sh 127.0.0.1 22
```

The script validates the host input, resolves it using `getent`, attempts a basic ICMP ping when available, prints network interface information when `ip` is available, and optionally checks a TCP port using `nc` or Bash `/dev/tcp`.

A failed ping does not necessarily mean the host is down: ICMP may be blocked by a firewall. DNS resolution and TCP results are reported separately. Invalid input returns a non-zero exit code.

## Logging

Each script appends timestamped descriptions to `logs/assignment-1.log`. Log files are runtime output and should not be committed. The `.gitignore` excludes them while `.gitkeep` preserves the directory.

## Tests

```bash
./grade.sh
```

The local grader checks required files, Bash syntax, executable permissions, core output, disk input validation, network input validation, logging, and basic Git history. It is a self-authored sanity checker, not an official TS Academy grading script.

You can also test manually:

```bash
./disk-check.sh 101; echo "exit=$?"
./disk-check.sh abc; echo "exit=$?"
./network-check.sh; echo "exit=$?"
./network-check.sh example.com 70000; echo "exit=$?"
```

## Git workflow requirement

Use a feature branch and merge it into `main`. Example workflow (run from the repository root):

```bash
git init
git branch -M main
git add README.md .gitignore system-info.sh disk-check.sh network-check.sh grade.sh logs/.gitkeep
git commit -m "chore: initialize diagnostic toolkit structure"
git switch -c feature/system-diagnostics
# Make and commit incremental improvements on this branch.
git add system-info.sh
git commit -m "feat: add runtime system information report"
git add disk-check.sh
git commit -m "feat: add threshold-based disk usage check"
git add network-check.sh
git commit -m "feat: add host resolution and connectivity checks"
git add README.md grade.sh .gitignore
git commit -m "test: document usage and add local validation"
git switch main
git merge --no-ff feature/system-diagnostics -m "merge: add diagnostic toolkit feature"
git log --oneline --graph --decorate -10
```

For the required five meaningful commits, make at least five separate commits; do not create empty or misleading commits. If your files are already complete before the first commit, you can still commit them in logical groups. Keep `logs/assignment-1.log` out of Git.

## Assumptions and limitations

- The project targets Linux and Bash, not native PowerShell.
- Some networks block ICMP; ping failure is reported but does not automatically mean DNS or TCP connectivity failed.
- TCP checks require `nc` or Bash support for `/dev/tcp`.
- The logs directory must be writable by the user running the scripts.
