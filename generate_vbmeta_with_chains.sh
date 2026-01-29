#!/bin/bash
# generate_vbmeta_with_chains.sh
# This script creates a vbmeta.img with proper chain descriptors for all partitions

VBMETA_KEY="rsa4096_vbmeta.pem"
OUTPUT="vbmeta-sign-custom.img"

# Extract public keys from PEM files
openssl rsa -in rsa4096_boot_pub.bin -pubout -outform DER -out boot_pub.der 2>/dev/null || \
    cp keys/rsa4096_boot_pub.bin boot_pub.der

openssl rsa -in rsa4096_recovery_pub.bin -pubout -outform DER -out recovery_pub.der 2>/dev/null || \
    cp keys/rsa4096_recovery_pub.bin recovery_pub.der

openssl rsa -in rsa4096_vbmeta_system_pub.bin -pubout -outform DER -out vbmeta_system_pub.der 2>/dev/null || \
    cp keys/rsa4096_vbmeta_system_pub.bin vbmeta_system_pub.der

openssl rsa -in rsa4096_vbmeta_vendor_pub.bin -pubout -outform DER -out vbmeta_vendor_pub.der 2>/dev/null || \
    cp keys/rsa4096_vbmeta_vendor_pub.bin vbmeta_vendor_pub.der

# Build vbmeta command with chain descriptors
CMD="python avbtool make_vbmeta_image \
    --algorithm SHA256_RSA4096 \
    --key $VBMETA_KEY \
    --rollback_index 2 \
    --chain_partition boot:1:boot_pub.der \
    --chain_partition dtbo:10:boot_pub.der \
    --chain_partition recovery:2:recovery_pub.der \
    --chain_partition vbmeta_system:3:vbmeta_system_pub.der \
    --chain_partition vbmeta_vendor:4:vbmeta_vendor_pub.der"

# Add additional chain partitions if they exist in the original
if [ -f "keys/rsa4096_socko_pub.bin" ]; then
    CMD="$CMD --chain_partition socko:11:keys/rsa4096_socko_pub.bin"
fi

if [ -f "keys/rsa4096_odmko_pub.bin" ]; then
    CMD="$CMD --chain_partition odmko:12:keys/rsa4096_odmko_pub.bin"
fi

if [ -f "keys/rsa4096_modem_pub.bin" ]; then
    CMD="$CMD --chain_partition l_modem:6:keys/rsa4096_modem_pub.bin"
    CMD="$CMD --chain_partition l_ldsp:7:keys/rsa4096_modem_pub.bin"
    CMD="$CMD --chain_partition l_gdsp:8:keys/rsa4096_modem_pub.bin"
    CMD="$CMD --chain_partition pm_sys:9:keys/rsa4096_modem_pub.bin"
fi

CMD="$CMD --output $OUTPUT"

echo "=== Generating vbmeta with chain descriptors ==="
echo "$CMD"
echo ""

eval $CMD

# Verify the result
if [ -f "$OUTPUT" ]; then
    echo ""
    echo "=== Verification ==="
    python avbtool info_image --image "$OUTPUT"
fi
