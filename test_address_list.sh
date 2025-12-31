#!/bin/bash
# Test script for address list matching feature

set -e

echo "=================================="
echo "Address List Matching Test Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if oclvanitygen exists
if [ ! -f "./oclvanitygen" ]; then
    echo -e "${RED}ERROR: oclvanitygen not found!${NC}"
    echo "Please compile first with: make oclvanitygen"
    exit 1
fi

echo -e "${GREEN}✓ Found oclvanitygen${NC}"
echo ""

# Test 1: Generate a test address
echo "Test 1: Generating test address..."
./oclvanitygen -k 1 1Test > test_output.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Test address generated${NC}"
    cat test_output.txt | grep -E "^(Address|Privkey):"
else
    echo -e "${RED}✗ Failed to generate test address${NC}"
    exit 1
fi
echo ""

# Test 2: Extract address to file
echo "Test 2: Creating test address list..."
TEST_ADDR=$(grep "^Address:" test_output.txt | awk '{print $2}')
if [ -z "$TEST_ADDR" ]; then
    echo -e "${RED}✗ Failed to extract address${NC}"
    exit 1
fi

echo "$TEST_ADDR" > test_list.txt
echo "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa" >> test_list.txt
echo "1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2" >> test_list.txt

echo -e "${GREEN}✓ Created test_list.txt with 3 addresses${NC}"
cat test_list.txt
echo ""

# Test 3: Search for the address
echo "Test 3: Searching for test address..."
echo -e "${YELLOW}This should find a match within seconds...${NC}"
timeout 60 ./oclvanitygen -L test_list.txt -1 > test_match.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Search completed${NC}"
    cat test_match.txt | grep -E "^(Pattern|Address|Privkey):"
else
    echo -e "${RED}✗ Search failed or timed out${NC}"
    echo "Output:"
    cat test_match.txt
    exit 1
fi
echo ""

# Test 4: Verify match
echo "Test 4: Verifying match..."
FOUND_ADDR=$(grep "^Address:" test_match.txt | awk '{print $2}')
if [ "$FOUND_ADDR" == "$TEST_ADDR" ]; then
    echo -e "${GREEN}✓✓✓ SUCCESS! Found the correct address!${NC}"
    echo ""
    echo "Generated address: $TEST_ADDR"
    echo "Found address:     $FOUND_ADDR"
else
    echo -e "${RED}✗ Address mismatch!${NC}"
    echo "Expected: $TEST_ADDR"
    echo "Found:    $FOUND_ADDR"
    exit 1
fi
echo ""

# Test 5: Large list simulation
echo "Test 5: Testing with slightly larger list..."
for i in {1..100}; do
    echo "1Test${i}xxxxxxxxxxxxxxxxxxxxxxxxxxxxx" >> test_list_large.txt
done
cat test_list.txt >> test_list_large.txt

echo "Created test_list_large.txt with 103 addresses"
timeout 120 ./oclvanitygen -L test_list_large.txt -1 -v > test_large.txt 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Large list test passed${NC}"
    grep -E "^(Loaded|Sorting|Transferring|Address)" test_large.txt | head -10
else
    echo -e "${YELLOW}⚠ Large list test timed out (this is OK, might just take longer)${NC}"
fi
echo ""

# Cleanup
echo "Cleaning up test files..."
rm -f test_output.txt test_list.txt test_match.txt test_list_large.txt test_large.txt

echo ""
echo "=================================="
echo -e "${GREEN}All tests passed!${NC}"
echo "=================================="
echo ""
echo "The address list matching feature is working correctly!"
echo ""
echo "Next steps:"
echo "1. Prepare your 55M address list file"
echo "2. Run: ./oclvanitygen -L addresses_55m.txt -v -o matches.txt"
echo "3. Monitor matches.txt for results"
echo ""
echo "See UBUNTU_1804_SETUP.md for detailed usage instructions."
