#!/bin/bash
set -e

echo "[+] (Plaintext) Stopping any existing iperf3 server on h2..."
ip netns exec h2 pkill iperf3 2>/dev/null || true

echo "[+] (Plaintext) Starting iperf3 server in background on h2..."
ip netns exec h2 iperf3 -s -D

echo "[+] (Plaintext) Starting tcpdump capture on WAN interface (wan-gw1)..."
ip netns exec wan tcpdump -i wan-gw1 -n -s 256 -w plain_capture.pcap >/dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 1

echo "[+] (Plaintext) Generating ICMP traffic: h1 pinging h2..."
ip netns exec h1 ping -c 4 10.0.2.2

echo "[+] (Plaintext) Generating TCP traffic: h1 running iperf3 client against h2..."
ip netns exec h1 iperf3 -c 10.0.2.2 -t 2 -b 10M -l 128

echo "[+] (Plaintext) Stopping tcpdump..."
sleep 1
kill $TCPDUMP_PID
wait $TCPDUMP_PID 2>/dev/null || true
echo "[+] (Plaintext) Plaintext test completed! Capture saved to plain_capture.pcap"