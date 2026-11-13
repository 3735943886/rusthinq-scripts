#!/usr/bin/env bash
# Capture every device's packets into OUTDIR/<device>.jsonl, surviving daemon restarts.
#
#   sudo ./capture-all.sh CONFIG.toml OUTDIR [--cloud]
#
# The management bind, user and password are re-read from CONFIG.toml's [management]
# section on every (re)connect, so an embedded daemon that picks a new port and password
# on each start is followed. Captures append; each reconnect starts with a session record.
# Ctrl-C stops everything.
set -u

config=${1:?usage: capture-all.sh CONFIG.toml OUTDIR [--cloud]}
out=${2:?usage: capture-all.sh CONFIG.toml OUTDIR [--cloud]}
shift 2
mkdir -p "$out"

management() { sed -n "/^\[management\]/,/^\[/s/^$1 = \"\(.*\)\"$/\1/p" "$config"; }

trap 'trap - INT TERM; kill 0; exit 130' INT TERM
while :; do
    bind=$(management bind)
    # A wildcard bind is not an address to connect to, and rusthinqctl refuses it.
    case $bind in 0.0.0.0:*) bind=127.0.0.1:${bind#*:} ;; esac
    export RUSTHINQ_API="http://$bind/"
    # rusthinqctl also refuses empty credentials, so an open daemon gets none.
    unset RUSTHINQ_USER RUSTHINQ_PASSWORD
    user=$(management user)
    if [ -n "$user" ]; then
        export RUSTHINQ_USER="$user" RUSTHINQ_PASSWORD="$(management password)"
    fi
    ids=$(rusthinqctl devices 2>/dev/null |
        python3 -c 'import json,sys; print("\n".join(json.load(sys.stdin)["devices"]))' 2>/dev/null)
    if [ -z "$ids" ]; then
        sleep 5
        continue
    fi
    echo "$(date '+%F %T') capturing $(echo "$ids" | wc -l) devices via $RUSTHINQ_API" >&2
    pids=()
    for id in $ids; do
        rusthinqctl capture "$id" "$out/$id.jsonl" "$@" </dev/null >/dev/null &
        pids+=($!)
    done
    # One capture ending (daemon restart, lost cloud feed) restarts the whole set,
    # which also picks up devices added since.
    wait -n
    kill "${pids[@]}" 2>/dev/null
    wait
    echo "$(date '+%F %T') capture ended; reconnecting" >&2
    sleep 5
done
