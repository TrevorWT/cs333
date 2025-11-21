#!/bin/bash
set -euo pipefail

mkdir -p ./out
files=${1:-10}
threads=${2:-4}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Testing thread_hash Implementation"
echo "========================================"
echo ""

# Test counter
PASS=0
FAIL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local expected_exit="$2"
    shift 2
    local cmd="$@"

    echo -n "Test: $test_name ... "

    set +e
    $cmd > /dev/null 2>&1
    actual_exit=$?
    set -e

    if [ "$actual_exit" -eq "$expected_exit" ]; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC} (expected exit $expected_exit, got $actual_exit)"
        FAIL=$((FAIL + 1))
    fi
}

myProg="../thread_hash"

# Check if program exists
if [ ! -f "$myProg" ]; then
    echo -e "${RED}Error: $myProg not found. Build the program first.${NC}"
    exit 1
fi

echo "--- Error Handling Tests ---"
run_test "Help option -h" 0 $myProg -h
run_test "Missing -d argument" 1 $myProg -i ./hashes-10.txt
run_test "Missing -i argument" 1 $myProg -d ./passwords-10.txt
run_test "Missing both -i and -d" 1 $myProg -t 4
run_test "Nonexistent hash file" 1 $myProg -i ./nonexistent.txt -d ./passwords-10.txt
run_test "Nonexistent dictionary file" 1 $myProg -i ./hashes-10.txt -d ./nonexistent.txt
run_test "Invalid -t value (0)" 0 $myProg -i ./hashes-10.txt -d ./passwords-10.txt -t 0
run_test "Invalid -t value (negative)" 0 $myProg -i ./hashes-10.txt -d ./passwords-10.txt -t -5
run_test "Invalid -t value (too large)" 0 $myProg -i ./hashes-10.txt -d ./passwords-10.txt -t 100
run_test "Invalid -t value (non-numeric)" 0 $myProg -i ./hashes-10.txt -d ./passwords-10.txt -t abc

echo ""
echo "--- Functional Tests ---"

case $files in
    50)
        input="-i ./hashes-50.txt"
        dictionary="-d ./passwords-50.txt"
        ;;
    100)
        input="-i ./hashes-100.txt"
        dictionary="-d ./passwords-100.txt"
        ;;
    250)
        input="-i ./hashes-250.txt"
        dictionary="-d ./passwords-250.txt"
        ;;
    500)
        input="-i ./hashes-500.txt"
        dictionary="-d ./passwords-500.txt"
        ;;
    1000)
        input="-i ./hashes-1000.txt"
        dictionary="-d ./passwords-1000.txt"
        ;;
    *)
        input="-i ./hashes-10.txt"
        dictionary="-d ./passwords-10.txt"
        ;;
esac

hisProg="./thread_hash"
hisOut="./out/his.out"
hisErr="./out/his.err"

myOut="./out/my.out"
myErr="./out/my.err"

# Check if reference implementation exists, if not skip comparison
if [ ! -f "$hisProg" ]; then
    echo -e "${YELLOW}Reference implementation not found. Skipping comparison tests.${NC}"
else
    echo "Running comparison test with $files files and $threads threads..."

    $hisProg $dictionary $input -t $threads > $hisOut 2> $hisErr
    $myProg $dictionary $input -t $threads > $myOut 2> $myErr

    # Extract only the total line and strip timing information
    grep '^total:' $hisErr | sed 's/[0-9]\+\.[0-9]\+ sec/X.XX sec/g' > ./out/his.sorted.err
    grep '^total:' $myErr | sed 's/[0-9]\+\.[0-9]\+ sec/X.XX sec/g' > ./out/my.sorted.err
    rm -- "./out/his.err" "./out/my.err"

    sort $hisOut > ./out/his.sorted.out && rm -- "./out/his.out"
    sort $myOut > ./out/my.sorted.out && rm -- "./out/my.out"

    diff -u ./out/his.sorted.out ./out/my.sorted.out > ./out/diff.out 2>&1 || true
    diff -u ./out/his.sorted.err ./out/my.sorted.err >> ./out/diff.out 2>&1 || true

    if [ -s ./out/diff.out ]; then
        echo -e "${RED}Output comparison FAILED${NC}"
        echo "Differences found in ./out/diff.out"
        FAIL=$((FAIL + 1))
    else
        echo -e "${GREEN}Output comparison PASSED${NC}"
        PASS=$((PASS + 1))
    fi
fi

# Test with different thread counts
echo ""
echo "--- Thread Count Tests ---"
for t in 1 2 4 8; do
    echo -n "Testing with $t thread(s)... "
    set +e
    $myProg $dictionary $input -t $t > /dev/null 2>&1
    result=$?
    set -e
    if [ $result -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC}"
        FAIL=$((FAIL + 1))
    fi
done

# Cleanup empty files
for f in ./out/*.out; do
    if [ -f "$f" ] && [ ! -s "$f" ]; then
        rm -- "$f"
    fi
done

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo -e "Passed: ${GREEN}$PASS${NC}"
echo -e "Failed: ${RED}$FAIL${NC}"
echo "========================================"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
