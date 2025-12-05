#!/bin/bash

echo "========================================="
echo "Running all client tests"
echo "========================================="
echo ""

# Clean up old outputs
rm -f out/*.txt out/*.diff

# Run all test combinations
echo "Test 1: Your client → Your server (port 10056)"
../test_client.bash ../rockem_client my_client_my_server.txt 127.0.0.1 10056
sleep 1

echo ""
echo "Test 2: Instructor's client → Your server (port 10056)"
../test_client.bash ../rockem_client_i his_client_my_server.txt 127.0.0.1 10056
sleep 1

echo ""
echo "Test 3: Instructor's client → Instructor's server (port 10057) [BASELINE]"
../test_client.bash ../rockem_client_i his_client_his_server.txt 127.0.0.1 10057
sleep 1

echo ""
echo "Test 4: Your client → Instructor's server (port 10057)"
../test_client.bash ../rockem_client my_client_his_server.txt 127.0.0.1 10057
sleep 1

# Clean up test files
rm -f file*.txt test_upload.txt sleep_test.txt test.txt

echo ""
echo "========================================="
echo "Comparing outputs against baseline"
echo "========================================="
echo ""

BASELINE="out/his_client_his_server.txt"
DIFF_DIR="out"

# Compare each output to the baseline
echo "Comparing my_client_my_server.txt to baseline..."
diff -u "$BASELINE" "$DIFF_DIR/my_client_my_server.txt" > "$DIFF_DIR/my_client_my_server.diff"
if [ $? -eq 0 ]; then
    echo "  ✓ No differences found"
    rm "$DIFF_DIR/my_client_my_server.diff"
else
    echo "  ✗ Differences found - saved to my_client_my_server.diff"
    echo "    $(wc -l < "$DIFF_DIR/my_client_my_server.diff") lines differ"
fi

echo ""
echo "Comparing his_client_my_server.txt to baseline..."
diff -u "$BASELINE" "$DIFF_DIR/his_client_my_server.txt" > "$DIFF_DIR/his_client_my_server.diff"
if [ $? -eq 0 ]; then
    echo "  ✓ No differences found"
    rm "$DIFF_DIR/his_client_my_server.diff"
else
    echo "  ✗ Differences found - saved to his_client_my_server.diff"
    echo "    $(wc -l < "$DIFF_DIR/his_client_my_server.diff") lines differ"
fi

echo ""
echo "Comparing my_client_his_server.txt to baseline..."
diff -u "$BASELINE" "$DIFF_DIR/my_client_his_server.txt" > "$DIFF_DIR/my_client_his_server.diff"
if [ $? -eq 0 ]; then
    echo "  ✓ No differences found"
    rm "$DIFF_DIR/my_client_his_server.diff"
else
    echo "  ✗ Differences found - saved to my_client_his_server.diff"
    echo "    $(wc -l < "$DIFF_DIR/my_client_his_server.diff") lines differ"
fi

echo ""
echo "========================================="
echo "Summary"
echo "========================================="
echo "All test outputs saved to: out/"
echo ""

# Check if any diff files exist
if ls out/*.diff 1> /dev/null 2>&1; then
    echo "Diff files found:"
    ls -lh out/*.diff
    echo ""
    echo "To view all differences:"
    echo "  cat out/*.diff"
else
    echo "✓ No differences found - all outputs match the baseline!"
    echo "  All implementations are working identically."
fi
