#!/bin/bash
# Universal automated server test - works for any server executable
# Usage: ./test_server.bash <server_executable> <output_file> [port]

if [ $# -lt 2 ]; then
    echo "Usage: $0 <server_executable> <output_file> [port]"
    echo "Example: $0 ./rockem_server myout.txt 10056"
    echo "Example: $0 ./sample/rockem_server hisout.txt 10057"
    exit 1
fi

SERVER_EXEC="$1"
OUTPUT_FILE="$2"
PORT="${3:-10055}"  # Default port 10050 if not specified

# Create out directory if it doesn't exist
OUT_DIR="out"
mkdir -p "$OUT_DIR"

# Prepend out/ to output file path
OUTPUT_PATH="$OUT_DIR/$OUTPUT_FILE"

if [ ! -x "$SERVER_EXEC" ]; then
    echo "Error: $SERVER_EXEC is not executable or does not exist"
    exit 1
fi

echo "Running automated tests on: $SERVER_EXEC"
echo "Output will be saved to: $OUTPUT_PATH"
echo "Using port: $PORT"
echo ""

# Send all commands to the server via stdin
(
    sleep 1
    echo "help"
    sleep 1
    echo "count"
    sleep 1
    echo "v+"
    sleep 1
    echo "count"
    sleep 1
    echo "v-"
    sleep 1
    echo "count"
    sleep 1
    echo "u+"
    sleep 1
    echo "count"
    sleep 1
    echo "u-"
    sleep 1
    echo "count"
    sleep 1
    echo "badcommand"
    sleep 1
    echo "exit"
) | "$SERVER_EXEC" -v -p "$PORT" > "$OUTPUT_PATH" 2>&1

echo "Testing complete. Output saved to $OUTPUT_PATH"
echo ""
echo "View the output with: cat $OUTPUT_PATH"
