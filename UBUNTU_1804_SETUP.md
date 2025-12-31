# Ubuntu 18.04 Setup Guide for GPU Address List Matching

## Prerequisites
- Ubuntu 18.04 LTS (Bionic Beaver) - MATE or Desktop
- NVIDIA GeForce GTX 1070 (or compatible GPU)
- NVIDIA drivers installed
- At least 2 GB free RAM (for loading 55M addresses)

## Step 1: Install Required Packages

```bash
# Update package list
sudo apt-get update

# Install build tools and dependencies
sudo apt-get install -y \
    build-essential \
    git \
    libssl-dev \
    libpcre3-dev \
    ocl-icd-opencl-dev \
    nvidia-opencl-dev \
    nvidia-cuda-toolkit

# Verify installations
gcc --version          # Should show GCC 7.x or 8.x
openssl version        # Should show OpenSSL 1.1.0g or 1.1.1
```

## Step 2: Verify GPU Setup

```bash
# Check if NVIDIA GPU is detected
nvidia-smi

# Should show GTX 1070 and driver version
# Example output:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 418.67       Driver Version: 418.67       CUDA Version: 10.1    |
# |-------------------------------+----------------------+----------------------+
# |   0  GeForce GTX 1070    Off  | 00000000:01:00.0 On  |                  N/A |
# +-----------------------------------------------------------------------------+

# Check OpenCL devices
clinfo | grep -i "device name"
# Should list your GTX 1070
```

## Step 3: Clone and Build Vanitygen

```bash
# Clone your repository
cd ~
git clone https://github.com/jamiestorage100/vanitygen.git
cd vanitygen

# Checkout the feature branch
git checkout feature-address-list-matching

# Clean and build
make clean
make oclvanitygen

# If successful, you should see:
# cc -ggdb -O3 -Wall   -c -o oclvanitygen.o oclvanitygen.c
# cc -ggdb -O3 -Wall   -c -o oclengine.o oclengine.c
# cc -ggdb -O3 -Wall   -c -o pattern.o pattern.c
# cc -ggdb -O3 -Wall   -c -o util.o util.c
# cc oclvanitygen.o oclengine.o pattern.o util.o -o oclvanitygen (CFLAGS) (LIBS) (OPENCL_LIBS)
```

## Step 4: Test Basic Functionality

```bash
# Test 1: List available OpenCL devices
./oclvanitygen

# Test 2: Generate a simple vanity address (without address list)
./oclvanitygen 1Test

# Should output something like:
# Difficulty: 4553521
# Pattern: 1Test
# Address: 1Testxxx...
# Privkey: 5xxx...
```

## Step 5: Test Address List Feature

```bash
# Create a test address list file
cat > test_addresses.txt <<'EOF'
# Test addresses - one per line
1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa
1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2
1CounterpartyXXXXXXXXXXXXXXXUWLpVr
1111111111111111111114oLvT2
12345678901234567890123456789012
EOF

# Run with address list
./oclvanitygen -L test_addresses.txt -v

# Expected output:
# Loading address list from test_addresses.txt...
# Loaded 5 addresses (0.00 MB)
# Sorting addresses for fast lookup...
# Sorting complete.
# Transferring 5 addresses (0.00 MB) to GPU...
# Device: GeForce GTX 1070
# Starting search...
# [XX.X Mkey/s][Total: XXXXX keys][Runtime: Xs]
```

## Step 6: Test with Generated Address

```bash
# Generate a test address and extract it
./oclvanitygen -k 1 1Test > test_output.txt

# Extract just the address line
grep "^Address:" test_output.txt | awk '{print $2}' > known_address.txt

# Now search for this known address
./oclvanitygen -L known_address.txt -v

# It should find it and output:
# Pattern: <filename>
# Address: 1Testxxx... (same as generated)
# Privkey: 5xxx... (same as generated)
```

## Step 7: Prepare Your 55M Address List

```bash
# Copy your 55 million address file to the vanitygen directory
# Assuming it's named addresses_55m.txt

# Check file size
ls -lh addresses_55m.txt
# Should be around 2.1 GB

# Count lines (optional - takes a few seconds)
wc -l addresses_55m.txt
# Should show ~55000000

# Run the search
./oclvanitygen -L addresses_55m.txt -v -o matches.txt

# Expected startup output:
# Loading address list from addresses_55m.txt...
#   Loaded 1 M addresses...
#   Loaded 2 M addresses...
#   ...
#   Loaded 55 M addresses...
# Loaded 55000000 addresses (1048.58 MB)
# Sorting addresses for fast lookup...
# Sorting complete.
# Transferring 55000000 addresses (1048.58 MB) to GPU...
# Device: GeForce GTX 1070
# Starting search...
# [30-40 Mkey/s][Total: XXXXX keys][Runtime: XXXs]

# When a match is found:
# Pattern: addresses_55m.txt
# Address: 1xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Privkey: 5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## Command Line Options

```bash
# Show help
./oclvanitygen -h

# Key options for address list mode:
-L <file>     Address list file (one address per line)
-v            Verbose output (shows loading progress)
-o <file>     Write matches to file (default: console only)
-k            Keep searching after finding matches
-1            Stop after first match
-d <device>   Select specific GPU device number
-D <devstr>   Specify device with custom settings
```

## Performance Tuning

### For GTX 1070:
```bash
# Let auto-detect work first
./oclvanitygen -L addresses.txt

# If you want to tune manually:
./oclvanitygen -L addresses.txt -d 0 -w 256 -g 256x128

# -d 0         : Use device 0 (your GTX 1070)
# -w 256       : Work items per thread
# -g 256x128   : Grid size (rows x columns)
```

## Expected Performance

### GTX 1070 with 55M addresses:
- **Loading time**: 30-60 seconds (includes sorting)
- **GPU transfer**: 5-10 seconds
- **Search speed**: 30-40 million keys/second
- **Memory usage**: ~1.1 GB GPU RAM

### Without address list (baseline):
- **Search speed**: 50+ million keys/second

## Troubleshooting

### Issue: "command not found: clinfo"
```bash
sudo apt-get install clinfo
```

### Issue: "No OpenCL platforms found"
```bash
# Reinstall NVIDIA OpenCL support
sudo apt-get install --reinstall nvidia-opencl-dev ocl-icd-opencl-dev

# Reboot
sudo reboot
```

### Issue: "Could not open address list file"
```bash
# Check file exists and is readable
ls -l addresses_55m.txt
cat addresses_55m.txt | head -5

# Check permissions
chmod 644 addresses_55m.txt
```

### Issue: Compilation errors about BIGNUM
If you still see errors about "incomplete type" for BIGNUM, check OpenSSL version:
```bash
openssl version
# Must be 1.0.x or 1.1.x, NOT 3.0.x

# If 3.0.x, you're on Ubuntu 22.04+ (wrong version)
# You need Ubuntu 18.04 or 20.04
```

### Issue: Low performance (<20 Mkey/s)
```bash
# Check GPU isn't throttling
nvidia-smi
# Look for temperature and power usage

# Try with smaller grid first
./oclvanitygen -L addresses.txt -g 128x64

# Check GPU utilization
watch -n 1 nvidia-smi
# GPU-Util should be 90-100%
```

## Next Steps

Once everything is working:
1. Run overnight with your 55M address list
2. Monitor matches.txt for any findings
3. Save any found private keys securely
4. Consider running in a `screen` session:
   ```bash
   screen -S vanitygen
   ./oclvanitygen -L addresses_55m.txt -o matches.txt -k
   # Press Ctrl+A, then D to detach
   # Later: screen -r vanitygen to reattach
   ```

## Security Reminders

- ⚠️ Private keys control Bitcoin funds
- ⚠️ Store matches.txt securely (encrypt if needed)
- ⚠️ Only search addresses you own or have permission to search
- ⚠️ This is for educational/recovery purposes only

## Support

If you encounter issues:
1. Check this guide thoroughly
2. Verify all dependencies are installed
3. Confirm OpenSSL version is 1.1.x
4. Test with small address list first (100-1000 addresses)
5. Check GPU is working with basic oclvanitygen test

Good luck with your search! 🚀
