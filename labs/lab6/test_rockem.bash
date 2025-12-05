#!/bin/bash

# Test script for rockem client/server
# Usage: ./test_rockem.bash

PORT=10050
SERVER_IP="127.0.0.1"
SERVER_PID=""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Rockem Client/Server Test Script"
echo "========================================="

# Check if binaries exist
if [ ! -f ./rockem_server ]; then
    echo -e "${RED}Error: rockem_server not found. Run 'make' first.${NC}"
    exit 1
fi

if [ ! -f ./rockem_client ]; then
    echo -e "${RED}Error: rockem_client not found. Run 'make' first.${NC}"
    exit 1
fi

# Start the server in background
echo -e "${YELLOW}Starting server on port $PORT...${NC}"
./rockem_server -p $PORT -v > server_output.txt 2>&1 &
SERVER_PID=$!
sleep 2

# Check if server is running
if ! ps -p $SERVER_PID > /dev/null; then
    echo -e "${RED}Error: Server failed to start${NC}"
    cat server_output.txt
    exit 1
fi
echo -e "${GREEN}Server started (PID: $SERVER_PID)${NC}"

# Function to cleanup
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
        wait $SERVER_PID 2>/dev/null
        echo -e "${GREEN}Server stopped${NC}"
    fi
    rm -f test_*.txt downloaded_* server_output.txt
}

trap cleanup EXIT

# Test 1: DIR command
echo -e "\n${YELLOW}Test 1: Directory listing (DIR)${NC}"
./rockem_client -p $PORT -c dir -i $SERVER_IP
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DIR test passed${NC}"
else
    echo -e "${RED}✗ DIR test failed${NC}"
fi

# Test 2: PUT command (send file to server)
echo -e "\n${YELLOW}Test 2: PUT command (send file to server)${NC}"
echo "This is a test file for PUT command" > test_put.txt
./rockem_client -p $PORT -c put -i $SERVER_IP test_put.txt
sleep 1
if [ -f test_put.txt ] && grep -q "test file for PUT" test_put.txt; then
    echo -e "${GREEN}✓ PUT test passed - file sent${NC}"
else
    echo -e "${RED}✗ PUT test failed${NC}"
fi

# Test 3: GET command (fetch file from server)
echo -e "\n${YELLOW}Test 3: GET command (fetch file from server)${NC}"
# First, ensure we have a file on the server
echo "File for GET test" > test_get.txt
./rockem_client -p $PORT -c put -i $SERVER_IP test_get.txt
sleep 1
# Remove local copy
rm -f test_get.txt
# Now try to GET it back
./rockem_client -p $PORT -c get -i $SERVER_IP test_get.txt
sleep 1
if [ -f test_get.txt ] && grep -q "File for GET test" test_get.txt; then
    echo -e "${GREEN}✓ GET test passed - file received${NC}"
else
    echo -e "${RED}✗ GET test failed${NC}"
fi

# Test 4: Multiple files with PUT
echo -e "\n${YELLOW}Test 4: Multiple files PUT${NC}"
echo "File 1" > test_multi1.txt
echo "File 2" > test_multi2.txt
echo "File 3" > test_multi3.txt
./rockem_client -p $PORT -c put -i $SERVER_IP test_multi1.txt test_multi2.txt test_multi3.txt
sleep 2
echo -e "${GREEN}✓ Multiple PUT test completed${NC}"

# Test 5: Multiple files with GET
echo -e "\n${YELLOW}Test 5: Multiple files GET${NC}"
rm -f test_multi*.txt
./rockem_client -p $PORT -c get -i $SERVER_IP test_multi1.txt test_multi2.txt test_multi3.txt
sleep 2
if [ -f test_multi1.txt ] && [ -f test_multi2.txt ] && [ -f test_multi3.txt ]; then
    echo -e "${GREEN}✓ Multiple GET test passed${NC}"
else
    echo -e "${RED}✗ Multiple GET test failed${NC}"
fi

# Test 6: Verbose mode
echo -e "\n${YELLOW}Test 6: Verbose mode test${NC}"
./rockem_client -p $PORT -c dir -i $SERVER_IP -v
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Verbose mode test passed${NC}"
else
    echo -e "${RED}✗ Verbose mode test failed${NC}"
fi

echo -e "\n${YELLOW}=========================================${NC}"
echo -e "${GREEN}All tests completed!${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo -e "Check server_output.txt for server logs"
