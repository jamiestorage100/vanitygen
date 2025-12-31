# GPU Address List Matching Feature

## Overview
Added GPU-accelerated address list searching functionality to oclvanitygen. This allows checking generated Bitcoin addresses against a preloaded list of up to 55+ million addresses (or more).

## Files Modified

### 1. util.h / util.c
Added functions for loading and managing address lists:
- `vg_decode_address_to_hash160()` - Decodes Base58 Bitcoin address to 20-byte hash160
- `vg_load_address_list()` - Loads addresses from file, decodes, and sorts them
- `vg_free_address_list()` - Frees allocated memory

### 2. calc_addrs.cl
Added new OpenCL kernel `hash_ec_point_search_list`:
- Performs binary search on GPU for each generated hash160
- Compares against sorted address list in GPU memory
- Returns match with cell index for private key reconstruction

### 3. oclengine.c
Added integration functions:
- `vg_ocl_addrlist_init()` - Initializes GPU buffers with address list
- `vg_ocl_addrlist_rekey()` - Resets match indicators
- `vg_ocl_addrlist_check()` - Checks for matches and outputs results
- `vg_ocl_context_set_address_list()` - Public API to configure address list

### 4. oclengine.h
- Added forward declaration for `vg_address_list_t`
- Added `vg_ocl_context_set_address_list()` function declaration

### 5. oclvanitygen.c
- Added `-L <file>` command-line option for address list file
- Integrated address list loading before GPU context creation
- Sets up address list on GPU after context initialization
- Proper cleanup of address list on exit

## Usage

```bash
# Create address list file (one address per line)
cat > addresses.txt <<EOF
1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
1CounterpartyXXXXXXXXXXXXXXXUWLpVr
EOF

# Run with address list
./oclvanitygen -L addresses.txt

# The program will:
# 1. Load and sort the addresses (shows progress)
# 2. Transfer to GPU memory
# 3. Generate addresses and check against the list
# 4. Display any matches with private keys
```

## Performance
- **Memory**: ~20 bytes per address (55M addresses = ~1.05 GB GPU RAM)
- **Search**: Binary search O(log N) per generated address
- **Expected Speed**: 30-40 M keys/s on GTX 1070 (vs 50 M without list)
- **Overhead**: ~26 comparisons per address for 55M list

## Address File Format
- One Bitcoin address per line
- Blank lines and lines starting with # are ignored
- Whitespace is trimmed
- Invalid addresses are skipped with warning

## Implementation Details

### Binary Search on GPU
The kernel converts the 32-bit uint hash160 representation to bytes and performs byte-wise comparison:
```c
while (low <= high) {
    mid = low + ((high - low) >> 1);
    cmp = hash160_ucmp_list(hash_bytes, &address_list[mid * 20]);
    if (cmp == 0) /* Match found */
    else if (cmp < 0) high = mid - 1;
    else low = mid + 1;
}
```

### Memory Management
- Address list allocated on host
- Sorted using qsort() with memcmp
- Transferred to GPU as READ_ONLY buffer
- Shared across all GPU work items

### Match Output
When a match is found:
- GPU kernel stores cell index and hash160
- Host reconstructs private key from cell index
- Outputs both address and private key (WIF format)
- Continues searching unless `-1` option used

## OpenSSL Compatibility Issue

**IMPORTANT**: The vanitygen codebase uses BIGNUM as stack-allocated structures, which is not supported in OpenSSL 1.1+ or 3.0 where BIGNUM is opaque.

### Solutions:

1. **Use Ubuntu 18.04 or earlier** (has OpenSSL 1.0.x)

2. **Build OpenSSL 1.0.x from source**:
```bash
wget https://www.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz
tar xzf openssl-1.0.2u.tar.gz
cd openssl-1.0.2u
./config --prefix=/opt/openssl-1.0.2 no-shared
make && sudo make install

# Build vanitygen
cd /path/to/vanitygen
make CFLAGS="-I/opt/openssl-1.0.2/include" LIBS="-L/opt/openssl-1.0.2/lib -lpcre -lcrypto -lm -lpthread"
```

3. **Use Docker with older Ubuntu**:
```dockerfile
FROM ubuntu:18.04
RUN apt-get update && apt-get install -y build-essential libssl-dev libpcre3-dev ocl-icd-opencl-dev
# Build vanitygen normally
```

## Testing

Create a test with known address:
```bash
# Generate an address
./oclvanitygen -k 1 1Test > test_output.txt

# Extract the address
grep "^Address:" test_output.txt | awk '{print $2}' > test_list.txt

# Search for it
./oclvanitygen -L test_list.txt

# Should find it and output the same private key
```

## Security Notes
- Generated private keys control Bitcoin funds
- Save `matches.txt` securely
- Only search for addresses you own or have permission to search
- Educational/research purposes only

## Future Enhancements
- Hash table for O(1) lookup (vs O(log N))
- Multi-GPU support with list sharding
- Checkpoint/resume functionality
- Progress statistics and ETA

## Author
Feature implemented as part of GPU address list matching enhancement for vanitygen.
