#!/bin/bash
# Sn1per test runner — sources each test_*.sh and runs all test_* functions

SN1PER_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

source "$SN1PER_ROOT/lib/bootstrap.sh"
source "$SN1PER_ROOT/lib/logging.sh"
source "$SN1PER_ROOT/lib/workspace.sh"
source "$SN1PER_ROOT/lib/nmap-parser.sh"
source "$SN1PER_ROOT/lib/mode-skeleton.sh"
source "$SN1PER_ROOT/lib/json.sh"

FIXTURES_DIR="$SN1PER_ROOT/tests/fixtures"

echo "Sn1per Test Runner"
echo "Root: $SN1PER_ROOT"
echo ""

if [[ $# -gt 0 ]]; then
  TEST_FILES=("$@")
else
  TEST_FILES=("$SN1PER_ROOT/tests"/test_*.sh)
fi

for tf in "${TEST_FILES[@]}"; do
  [[ -f "$tf" ]] || continue
  source "$tf"
done

ALL_TESTS=()
for tf in "${TEST_FILES[@]}"; do
  [[ -f "$tf" ]] || continue
  while IFS=$' \t\n' read -r line; do
    [[ -n "$line" ]] && ALL_TESTS+=("$line")
  done < <(grep -oP '^\s*test_\w+(?=\s*\(\s*\)\s*\{?)' "$tf" 2>/dev/null || true)
done

declare -A FILE_FOR_TEST
for tf in "${TEST_FILES[@]}"; do
  [[ -f "$tf" ]] || continue
  while IFS=$' \t\n' read -r line; do
    [[ -n "$line" ]] && FILE_FOR_TEST["$line"]="$tf"
  done < <(grep -oP '^\s*test_\w+(?=\s*\(\s*\)\s*\{?)' "$tf" 2>/dev/null || true)
done

current_file=""
for func in "${ALL_TESTS[@]}"; do
  tf="${FILE_FOR_TEST[$func]}"
  if [[ "$tf" != "$current_file" ]]; then
    current_file="$tf"
    echo "=== $(basename "$tf" .sh) ==="
  fi
  printf "  %-45s ... " "${func#test_}"
  (
    set -e
    "$func"
  ) >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "PASS"
    PASS=$((PASS + 1))
  else
    echo "FAIL (exit=$rc)"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Summary ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Total:  $((PASS + FAIL))"
if [[ $FAIL -gt 0 ]]; then
  echo "  Result: FAILED"
  exit 1
else
  echo "  Result: PASSED"
  exit 0
fi
