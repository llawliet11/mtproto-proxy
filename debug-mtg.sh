#!/bin/bash

# Debug script to test MTG command

echo "=== MTG Debug Test ==="

# Test the exact command from your logs
echo "Testing MTG command..."

# The command from your logs (but with correct internal port)
MTG_CMD="mtg simple-run 0.0.0.0:8443 eef054bb2548ec430f2a667abc6277110474656c656772616d2e70756e6368737461727465722e636f6d --concurrency 4096 --tcp-buffer 32768B --timeout 15s --antireplay-cache-size 256KB --domain-fronting-port 443"

echo "Command: $MTG_CMD"
echo ""

# Test if MTG binary exists and works
echo "Testing MTG binary..."
if command -v mtg &> /dev/null; then
    echo "✅ MTG binary found"
    mtg --version
else
    echo "❌ MTG binary not found"
    exit 1
fi

echo ""
echo "Testing MTG help..."
mtg simple-run --help

echo ""
echo "=== End Debug Test ==="
