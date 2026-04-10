#!/bin/bash

echo "[+] (Cleanup) Starting cleanup: deleting network namespaces..."
for ns in h1 gw1 wan gw2 h2; do
    ip netns del $ns 2>/dev/null || true
done
echo "[+] (Cleanup) Custom namespaces deleted successfully."