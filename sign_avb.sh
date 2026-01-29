#!/bin/bash
#part_name signed_img img_to_sign [size_mb]

PART_NAME=$1
SIGNED_IMG=$2
IMG_TO_SIGN=$3
SIZE_MB=$4

PROP_FILE=$(mktemp)
INFO_OUTPUT=$(python avbtool info_image --image "$SIGNED_IMG" 2>/dev/null)

# Extract partition size
PARTITION_SIZE=$(echo "$INFO_OUTPUT" | grep -E "^Image size:|^Original image size:" | head -1 | awk '{print $(NF-1)}')

# Extract all Props
echo "$INFO_OUTPUT" | grep "Prop:" > "$PROP_FILE"

# Build command
CMD="python avbtool add_hash_footer --image $IMG_TO_SIGN --partition_name $PART_NAME --key rsa4096_$PART_NAME.pem --algorithm SHA256_RSA4096"

# Handle partition size
if [ -z "$PARTITION_SIZE" ] && [ -n "$SIZE_MB" ]; then
    PARTITION_SIZE=$(($SIZE_MB * 1024 * 1024))
elif [ -z "$PARTITION_SIZE" ]; then
    echo "Error: Failed to extract partition size from image, and no size_mb provided." >&2
    rm "$PROP_FILE"
    exit 1
fi

CMD="$CMD --partition_size $PARTITION_SIZE"

# Add all properties
while IFS= read -r line; do
    if [ -n "$line" ]; then
        PROP_KEY=$(echo "$line" | sed -E "s/^\s*Prop:\s*([^ ]+).*$/\1/")
        PROP_VALUE=$(echo "$line" | sed -E "s/^\s*Prop:.*->\s*'([^']+)'.*$/\1/")
        if [ -n "$PROP_KEY" ] && [ -n "$PROP_VALUE" ]; then
            CMD="$CMD --prop $PROP_KEY:$PROP_VALUE"
        fi
    fi
done < "$PROP_FILE"

rm "$PROP_FILE"

echo "=== AVB Signing Info ==="
echo "$INFO_OUTPUT"
echo ""
echo "=== Executing Command ==="
echo "$CMD"
echo ""

eval $CMD
