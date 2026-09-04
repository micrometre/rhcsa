#!/bin/bash
# =============================================================================
# bpftrace.sh — Real-time anomaly & latency detector
# Traces execve syscalls for suspicious processes and monitors vfs_read latency.
# Outputs colour-coded, timestamped alerts to stdout and optionally to a log file.
# =============================================================================

set -euo pipefail

# ── Colour palette ───────────────────────────────────────────────────────────
RED='\033[0;91m'
YEL='\033[0;93m'
GRN='\033[0;92m'
CYN='\033[0;96m'
BLU='\033[0;94m'
MAG='\033[0;95m'
DIM='\033[2m'
BOLD='\033[1m'
RST='\033[0m'

# ── Tunables ─────────────────────────────────────────────────────────────────
LATENCY_THRESHOLD_MS="${BPF_LATENCY_MS:-50}"        # env-override or default 50ms
LOG_FILE="${BPF_LOG_FILE:-}"                         # optional: /var/log/bpf-alerts.log
SUSPICIOUS_REGEX="(nc -e|ncat -e|bash -i|/tmp/|/dev/tcp/|base64 -d)"
CONTAINER_EXCLUDE_REGEX="^(runc|runc:\[|containerd-shim|docker-init)"

# ── Counters ─────────────────────────────────────────────────────────────────
ALERT_COUNT=0
LATENCY_COUNT=0
EXEC_TOTAL=0
SKIP_COUNT=0
START_TS=$(date +%s)

# ── Helper functions ─────────────────────────────────────────────────────────
ts()   { date '+%Y-%m-%d %H:%M:%S'; }
info() { printf "${GRN}[+]${RST} ${DIM}%s${RST}  %s\n" "$(ts)" "$1"; }
warn() { printf "${YEL}[!]${RST} ${DIM}%s${RST}  ${YEL}%s${RST}\n" "$(ts)" "$1"; }
alert(){ printf "${RED}[!!]${RST} ${DIM}%s${RST} ${RED}${BOLD}%s${RST}\n" "$(ts)" "$1"; }
dim()  { printf "${DIM}    %s  %s${RST}\n" "$(ts)" "$1"; }

log_to_file() {
    [[ -n "$LOG_FILE" ]] && printf '[%s] %s\n' "$(ts)" "$1" >> "$LOG_FILE"
}

# ── Pre-flight checks ───────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    printf "${RED}[-] This script must be run as root.${RST}\n" >&2
    exit 1
fi

if ! command -v bpftrace &>/dev/null; then
    printf "${RED}[-] bpftrace is not installed or not in PATH.${RST}\n" >&2
    exit 1
fi

if ! command -v stdbuf &>/dev/null; then
    printf "${RED}[-] stdbuf (coreutils) is not installed or not in PATH.${RST}\n" >&2
    exit 1
fi

# ── Startup banner ───────────────────────────────────────────────────────────
BPFTRACE_VER=$(bpftrace --version 2>/dev/null | head -1 || echo "unknown")
KERNEL_VER=$(uname -r)
HOSTNAME_STR=$(hostname -f 2>/dev/null || hostname)

printf "\n"
printf "${CYN}${BOLD}  ┌──────────────────────────────────────────────────────────┐${RST}\n"
printf "${CYN}${BOLD}  │         BPF Anomaly & Latency Detector                   │${RST}\n"
printf "${CYN}${BOLD}  └──────────────────────────────────────────────────────────┘${RST}\n"
printf "\n"
printf "  ${BLU}Host${RST}       : ${BOLD}%s${RST}\n" "$HOSTNAME_STR"
printf "  ${BLU}Kernel${RST}     : %s\n" "$KERNEL_VER"
printf "  ${BLU}bpftrace${RST}   : %s\n" "$BPFTRACE_VER"
printf "  ${BLU}Threshold${RST}  : ${BOLD}%d ms${RST} (vfs_read latency)\n" "$LATENCY_THRESHOLD_MS"
printf "  ${BLU}Log file${RST}   : %s\n" "${LOG_FILE:-<none — set BPF_LOG_FILE to enable>}"
printf "  ${BLU}Started${RST}    : %s\n" "$(ts)"
printf "\n"

info "Attaching BPF probes (execve tracepoint, vfs_read kprobe/kretprobe)..."
info "Press Ctrl-C to stop and print session summary."
printf "\n"

# ── Signal handling / cleanup ────────────────────────────────────────────────
print_summary() {
    local elapsed=$(( $(date +%s) - START_TS ))
    local mins=$(( elapsed / 60 ))
    local secs=$(( elapsed % 60 ))
    printf "\n"
    printf "${CYN}${BOLD}  ┌──────────────────────────────────────────────────────────┐${RST}\n"
    printf "${CYN}${BOLD}  │                   Session Summary                        │${RST}\n"
    printf "${CYN}${BOLD}  └──────────────────────────────────────────────────────────┘${RST}\n"
    printf "\n"
    printf "  ${BLU}Duration${RST}          : ${BOLD}%dm %ds${RST}\n" "$mins" "$secs"
    printf "  ${BLU}Exec events seen${RST}  : %d\n" "$EXEC_TOTAL"
    printf "  ${BLU}Container skipped${RST} : %d\n" "$SKIP_COUNT"
    printf "  ${RED}Security alerts${RST}  : ${BOLD}%d${RST}\n" "$ALERT_COUNT"
    printf "  ${YEL}Latency warnings${RST} : ${BOLD}%d${RST}\n" "$LATENCY_COUNT"
    printf "\n"
    info "Probes detached. Goodbye."
    printf "\n"
}

cleanup() {
    print_summary
    # Kill any lingering bpftrace child
    kill 0 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# ── BPF program ──────────────────────────────────────────────────────────────
# The latency threshold is injected from the shell variable so it stays in sync.
BPF_PROGRAM="
tracepoint:syscalls:sys_enter_execve
{
    printf(\"EXEC,%s,%d,%s\n\", comm, pid, str(args->filename));
}

kretprobe:vfs_read
/@start[tid]/
{
    \$lat_ms = (nsecs - @start[tid]) / 1000000;
    if (\$lat_ms > ${LATENCY_THRESHOLD_MS}) {
        printf(\"LATENCY,%s,%d,vfs_read,%d\n\", comm, tid, \$lat_ms);
    }
    delete(@start[tid]);
}

kprobe:vfs_read
{
    @start[tid] = nsecs;
}
"

# ── Main event loop ──────────────────────────────────────────────────────────
stdbuf -oL bpftrace -e "$BPF_PROGRAM" 2>/dev/null | while IFS=',' read -r event comm pid detail metric; do
    case "$event" in
        "EXEC")
            (( EXEC_TOTAL++ )) || true

            # Skip known container-runtime processes to avoid false positives
            if [[ "$comm" =~ $CONTAINER_EXCLUDE_REGEX ]]; then
                (( SKIP_COUNT++ )) || true
                dim "exec skipped (container-runtime): $comm ($pid) -> $detail"
                continue
            fi

            if [[ "$detail" =~ $SUSPICIOUS_REGEX ]] || [[ "$comm" =~ (nc|ncat|netcat) ]]; then
                (( ALERT_COUNT++ )) || true
                alert "SUSPICIOUS EXEC -> $comm (PID $pid): $detail"
                logger -p auth.alert -t "BPF-Security" \
                    "Suspicious execution detected! Comm: $comm (PID: $pid) Path: $detail"
                log_to_file "ALERT  exec $comm (PID $pid) $detail"
            fi
            ;;

        "LATENCY")
            (( LATENCY_COUNT++ )) || true
            warn "HIGH DISK LATENCY -> $comm (TID $pid) vfs_read took ${metric}ms  [threshold: ${LATENCY_THRESHOLD_MS}ms]"
            logger -p kern.warn -t "BPF-Performance" \
                "High VFS Read Latency: $comm (TID: $pid took ${metric}ms)"
            log_to_file "WARN   latency $comm (TID $pid) ${metric}ms"
            ;;

        *)
            # Ignore unexpected/blank lines from bpftrace startup output
            ;;
    esac
done