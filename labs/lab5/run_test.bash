#!/bin/bash
# ...existing code...
usage() { echo "Usage: $(basename "$0") [-h] [-b BEGIN] [-e END] [-v]"; exit 1; }

INFILE="./hydra"
VERBOSE=0
BEGIN="1"
END="10"

while getopts "hb:e:v" opt; do
  case "$opt" in
    h) usage ;;
    b) BEGIN="$OPTARG" ;;
    e) END="$OPTARG" ;;
    v) VERBOSE=1 ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

if ! [[ "$BEGIN" =~ ^[0-9]+$ ]] || ! [[ "$END" =~ ^[0-9]+$ ]]; then
  echo "Error: BEGIN and END must be integers" >&2
  exit 3
fi

if [ "$BEGIN" -gt "$END" ]; then
  echo "Error: BEGIN must be <= END" >&2
  exit 1
fi

[ "$VERBOSE" -eq 1 ] && echo "verbose on"
[ -n "$BEGIN" ] && echo "begin: $BEGIN"
[ -n "$END" ] && echo "end: $END"

# ensure program exists and is executable
if [ ! -x "$INFILE" ]; then
  echo "Error: $INFILE not found or not executable" >&2
  exit 1
fi
# ...existing code...
for i in $(seq "$BEGIN" "$END"); do
    # Use timeout with SIGKILL fallback
    timeout -k 1s 2s "$INFILE" "$i" 2>/dev/null || {
        actual_exit=$?
        case $actual_exit in
            124) echo "$i -> TIMEOUT" ;;
            137|143) echo "$i -> KILLED" ;;
            138|139) echo "$i -> CRASH (bus/seg fault)" ;;
            *) echo "$i -> FAILED (exit $actual_exit)" ;;
        esac
        continue
    }
    actual_exit=$?
    echo "$i -> SUCCESS (exit $actual_exit)"
done
# ...existing code...