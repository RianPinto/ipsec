#!/bin/bash
# Don't use set -e, pkill/kill can return non-zero legitimately

MODE=${1:-tunnel}
if [[ "$MODE" != "tunnel" && "$MODE" != "transport" ]]; then
    echo "Usage: $0 [tunnel|transport]"
    exit 1
fi

# Both modes test h1 <-> h2 traffic
echo "[+] (IPsec Test) Stopping any existing iperf3 server on h2..."
ip netns exec h2 pkill iperf3 2>/dev/null || true

echo "[+] (IPsec Test) Starting iperf3 server in background on h2..."
ip netns exec h2 iperf3 -s -D

echo "[+] (IPsec Test) Starting tcpdump on WAN (wan-gw1)..."
ip netns exec wan tcpdump -i wan-gw1 -n -s 256 -w esp_capture_${MODE}.pcap ip proto 50 > /dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 1

if [[ "$MODE" == "transport" ]]; then
    echo "[+] (IPsec Test) Generating ICMP traffic: h1 pinging h2 (transport mode)..."
    ip netns exec h1 ping -c 8 10.0.2.2

    echo "[+] (IPsec Test) Generating TCP traffic: h1 -> h2 iperf3 (transport mode)..."
    ip netns exec h1 iperf3 -c 10.0.2.2 -t 5 -b 10M -l 128
else
    echo "[+] (IPsec Test) Generating ICMP traffic: h1 pinging h2 (tunnel mode)..."
    ip netns exec h1 ping -c 4 10.0.2.2

    echo "[+] (IPsec Test) Generating TCP traffic: h1 -> h2 iperf3 (tunnel mode)..."
    ip netns exec h1 iperf3 -c 10.0.2.2 -t 2 -b 10M -l 128
fi

echo "[+] (IPsec Test) Stopping tcpdump..."
sleep 2
kill $TCPDUMP_PID 2>/dev/null || true
wait $TCPDUMP_PID 2>/dev/null || true
echo "[+] (IPsec Test) IPsec $MODE test completed! Capture saved to esp_capture_${MODE}.pcap"