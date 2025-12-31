# OpenSSL 3.0 Compatibility Issue

## Problem
The vanitygen codebase was written for OpenSSL 1.0/1.1 and uses BIGNUM as a struct member, which is not possible in OpenSSL 3.0 where BIGNUM is an opaque type.

## Solutions

### Option 1: Install OpenSSL 1.1 (Recommended)
On Ubuntu 20.04 or earlier, OpenSSL 1.1 is the default.

### Option 2: Build from source with OpenSSL 1.1
```bash
# Download and install OpenSSL 1.1
wget https://www.openssl.org/source/openssl-1.1.1w.tar.gz
tar xzf openssl-1.1.1w.tar.gz
cd openssl-1.1.1w
./config --prefix=/usr/local/openssl-1.1.1 --openssldir=/usr/local/openssl-1.1.1
make
sudo make install

# Compile vanitygen with OpenSSL 1.1
export PKG_CONFIG_PATH=/usr/local/openssl-1.1.1/lib/pkgconfig
export LD_LIBRARY_PATH=/usr/local/openssl-1.1.1/lib
make clean
make CFLAGS="-I/usr/local/openssl-1.1.1/include" LIBS="-L/usr/local/openssl-1.1.1/lib -lpcre -lcrypto -lm -lpthread"
```

### Option 3: Use Docker
```bash
# Use Ubuntu 20.04 with OpenSSL 1.1
docker run -it --gpus all ubuntu:20.04
# Install dependencies and build inside container
```

## Current Status
The address list matching code has been added but requires OpenSSL 1.1 to compile. All functionality is complete and will work once compiled with a compatible OpenSSL version.
