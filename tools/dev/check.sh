#!/bin/sh
# All server checks in one go; exits non-zero when any check finds a problem, so it can guard a commit:
#   sh tools/dev/check.sh && git add -A && git commit -m "..." && git push
cd "$(dirname "$0")/../.." || exit 1
run() { out=$(node "$1" 2>&1); s=$?; echo "$out" | tail -3; return $s; }
run tools/dev/smoke.js && run tools/dev/fuzz.js && run tools/dev/exploit.js && run tools/dev/realsave.js
