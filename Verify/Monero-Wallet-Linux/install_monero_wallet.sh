#!/bin/bash

# Start process of downloading monero wallet
MONERO_HASHES_DL="https://www.getmonero.org/downloads/hashes.txt"
MONERO_WALLET_DL="https://downloads.getmonero.org/gui/linux64"
HASHES_FILE="monero_hashes.txt"
WALLET_ARCHIVE="monero-gui-linux64.tar.bz2"
WALLET_DIR="monero-gui-wallet"

if [[ -d "./$WALLET_DIR" ]]; then
	echo "It appears you already have the wallet downloaded."

	while true; do
	read -p "Would you like to reinstall it? (y/n) " yn

	case $yn in 
		y ) echo "Reinstalling monero wallet.";
			rm -rf "./$WALLET_DIR/"
			break;;
		n ) echo "Exiting.";
			exit 0;;
		* ) echo "Error: Invalid response, type y or n.";
	esac
	done
fi


sudo apt-get update

# Install gpg if needed
if ! command -v gpg &>/dev/null; then
	echo "gpg is not installed. Installing..."
	sudo apt-get install gpg -y
else
	echo "gpg is already installed, continuing..."
fi

# Install bzip2 if needed
if ! command -v bzip2 &>/dev/null; then
	echo "bzip2 is not installed. Installing..."
	sudo apt-get install bzip2 -y
else
	echo "bzip2 is already installed, continuing..."
fi



# Verify PGP of monero_hashes.txt
wget "$MONERO_HASHES_DL" -O "$HASHES_FILE"

# Verify the fingerprint of binaryfate.asc
# Trusted fingerprint for binaryFate <binaryfate@getmonero.org>
TRUSTED_FINGERPRINT="81AC591FE9C4B65C5806AFC3F0AF4D462A0BDF92"

echo "Verifying binaryfate.asc fingerprint..."
IMPORTED_FINGERPRINT=$(gpg --with-colons --import-options show-only --import binaryfate.asc | grep "fpr" | head -n 1 | cut -d: -f10)

if [[ "$IMPORTED_FINGERPRINT" == "$TRUSTED_FINGERPRINT" ]]; then
    echo "SUCCESS: binaryfate.asc fingerprint matches trusted fingerprint."
else
    echo "FAILURE: binaryfate.asc fingerprint DOES NOT MATCH trusted fingerprint!"
    echo "Expected: $TRUSTED_FINGERPRINT"
    echo "Found:    $IMPORTED_FINGERPRINT"
    echo "Exiting for security."
    rm "$HASHES_FILE"
    exit 1
fi

gpg --import binaryfate.asc >/dev/null 2>&1
gpg --verify "$HASHES_FILE" >/dev/null 2>&1

# Determine if the exit code of gpg is a success
if [[ $? -eq 0 ]]; then
	echo "SUCCESS: Vaid PGP for monero wallet hashes. Continuing..."
else
	echo "FAILURE: Invalid PGP for monero wallet hashes. Exiting."
	exit 1
fi

# Extract desired wallet hash from monero_hashes.txt file
MONERO_WALLET_HASH=$(grep "monero-gui-linux-x64-" "$HASHES_FILE" | cut -d' ' -f1)
rm "$HASHES_FILE"

# Download monero wallet
wget "$MONERO_WALLET_DL" -O "$WALLET_ARCHIVE"

# Verify file hash of the monero wallet
computed_hash=$(sha256sum "$WALLET_ARCHIVE" | awk '{print $1}')

echo "Monero wallet computed hash: $computed_hash"

if [[ "$computed_hash" = "$MONERO_WALLET_HASH" ]]; then
	echo "SUCCESS: Monero wallet hash verification successful. The file is intact and has not been tampered with."
else
	echo "FAILURE: Monero wallet hash verification failed. The file may be corrupted or tampered with."
	exit 1
fi

# Extract the monero wallet file
echo "Extracting monero wallet..."
mkdir "$WALLET_DIR"
tar -xjf "$WALLET_ARCHIVE" -C "./$WALLET_DIR"