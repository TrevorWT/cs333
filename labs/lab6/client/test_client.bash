#!/bin/bash
# Universal automated client test - works for any client executable
# Usage: ./test_client.bash <client_executable> <output_file> <server_ip> <server_port>

if [ $# -lt 4 ]; then
    echo "Usage: $0 <client_executable> <output_file> <server_ip> <server_port>"
    echo "Example: $0 ./rockem_client my_client_out.txt 127.0.0.1 10056"
    echo "Example: $0 ./sample/rockem_client his_client_out.txt 127.0.0.1 10057"
    echo ""
    echo "Note: Make sure the server is already running on the specified port!"
    exit 1
fi

CLIENT_EXEC="$1"
OUTPUT_FILE="$2"
SERVER_IP="$3"
SERVER_PORT="$4"

# Create out directory if it doesn't exist
OUT_DIR="out"
mkdir -p "$OUT_DIR"

# Prepend out/ to output file path
OUTPUT_PATH="$OUT_DIR/$OUTPUT_FILE"

if [ ! -x "$CLIENT_EXEC" ]; then
    echo "Error: $CLIENT_EXEC is not executable or does not exist"
    exit 1
fi

echo "Running automated client tests on: $CLIENT_EXEC" | tee "$OUTPUT_PATH"
echo "Server: $SERVER_IP:$SERVER_PORT" | tee -a "$OUTPUT_PATH"
echo "Output will be saved to: $OUTPUT_PATH" | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 1: Help option
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 1: Client help (-h)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -h 2>&1 | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 2: Directory listing
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 2: Directory listing (dir command)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -i "$SERVER_IP" -p "$SERVER_PORT" -c dir 2>&1 | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 3: Create and upload a file
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 3: Upload single file (PUT)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "Test content for upload" > test_upload.txt
"$CLIENT_EXEC" -i "$SERVER_IP" -p "$SERVER_PORT" -c put test_upload.txt 2>&1 | tee -a "$OUTPUT_PATH"
echo "Uploaded test_upload.txt" | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 4: Download a file
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 4: Download single file (GET)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -i "$SERVER_IP" -p "$SERVER_PORT" -c get test.txt 2>&1 | tee -a "$OUTPUT_PATH"
if [ -f test.txt ]; then
    echo "Successfully downloaded test.txt" | tee -a "$OUTPUT_PATH"
    echo "Content:" | tee -a "$OUTPUT_PATH"
    cat test.txt | tee -a "$OUTPUT_PATH"
else
    echo "ERROR: test.txt not downloaded" | tee -a "$OUTPUT_PATH"
fi
echo "" | tee -a "$OUTPUT_PATH"

# Test 5: Multiple file upload (tests threading)
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 5: Multiple file upload (threading test)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "File 1 content" > file1.txt
echo "File 2 content" > file2.txt
echo "File 3 content" > file3.txt
"$CLIENT_EXEC" -i "$SERVER_IP" -p "$SERVER_PORT" -c put file1.txt file2.txt file3.txt 2>&1 | tee -a "$OUTPUT_PATH"
echo "Uploaded multiple files" | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 6: Multiple file download (tests threading)
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 6: Multiple file download (threading test)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -i "$SERVER_IP" -p "$SERVER_PORT" -c get file1.txt file2.txt 2>&1 | tee -a "$OUTPUT_PATH"
echo "Downloaded multiple files" | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 7: Verbose mode
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 7: Verbose mode (-v)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -v -i "$SERVER_IP" -p "$SERVER_PORT" -c dir 2>&1 | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 8: Sleep mode (-u flag)
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 8: Sleep mode (-u flag)" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "Small test file" > sleep_test.txt
"$CLIENT_EXEC" -u -i "$SERVER_IP" -p "$SERVER_PORT" -c put sleep_test.txt 2>&1 | tee -a "$OUTPUT_PATH"
echo "Uploaded with sleep delay" | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

# Test 9: Combined flags (-v -u)
echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "TEST 9: Combined verbose and sleep flags" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"
"$CLIENT_EXEC" -v -u -i "$SERVER_IP" -p "$SERVER_PORT" -c dir 2>&1 | tee -a "$OUTPUT_PATH"
echo "" | tee -a "$OUTPUT_PATH"

echo "=========================================" | tee -a "$OUTPUT_PATH"
echo "All client tests completed" | tee -a "$OUTPUT_PATH"
echo "Output saved to: $OUTPUT_PATH" | tee -a "$OUTPUT_PATH"
echo "=========================================" | tee -a "$OUTPUT_PATH"

# Cleanup test files
rm -f test_upload.txt file1.txt file2.txt file3.txt sleep_test.txt test.txt
