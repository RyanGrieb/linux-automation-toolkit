# Verification Scripts

This directory contains shell scripts designed to assist with verifying digital signatures and verifying/installing software securely.

## Scripts

### 1. `verify.sh`

A general-purpose script to verify GPG signatures for any file or verify files against a SHA512 checksum. It automatically attempts to fetch missing public keys from a keyserver (`keyserver.ubuntu.com`) when verifying GPG signatures.

**Usage:**
```bash
# Verify with a GPG signature file
./verify.sh <file> <signature.asc>

# Verify with a SHA512 checksum string
./verify.sh <file> <sha512_checksum>
```

**Features:**
- Checks for GPG installation.
- Automatically retrieves keys if they are missing from your keyring (for GPG verification).
- Supports direct SHA512 checksum verification by pasting the hash as the second argument.
- Verifies the signature/checksum and outputs a clear Success/Failure status.

### 2. `Monero-Wallet-Linux/install_monero_wallet.sh`

A dedicated script to securely download, verify, and install the Monero GUI Wallet for Linux 64-bit systems.

**Usage:**
```bash
cd Monero-Wallet-Linux
./install_monero_wallet.sh
```

**Features:**
- **Secure Verification:** Verifies the `hashes.txt` file using the Monero Lead Maintainer's GPG key (`binaryfate`).
- **Fingerprint Checking:** Strictly enforces a fingerprint check (`81AC...`) against the provided key to prevent tampering.
- **Hash Validation:** Downloads the wallet and confirms the file integrity by comparing its SHA256 hash against the signed `hashes.txt`.
- **Automatic Setup:** Installs dependencies (`gpg`, `bzip2`), extracts the wallet, and manages re-installation if the directory exists.
