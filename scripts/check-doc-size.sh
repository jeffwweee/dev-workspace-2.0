#!/bin/bash
# check-doc-size.sh - Check if doc is large, recommend compact
# Usage: ./scripts/check-doc-size.sh <file_path>
# Returns: "recommend" if > 5KB, "ok" otherwise

DOC_FILE="$1"
SIZE_THRESHOLD_KB=5  # 5KB ≈ 1000+ tokens

if [ ! -f "$DOC_FILE" ]; then
  echo "error: File not found: $DOC_FILE"
  exit 1
fi

# Get file size in KB
SIZE_KB=$(du -k "$DOC_FILE" | cut -f1)

if [ "$SIZE_KB" -gt "$SIZE_THRESHOLD_KB" ]; then
  echo "recommend"
else
  echo "ok"
fi
