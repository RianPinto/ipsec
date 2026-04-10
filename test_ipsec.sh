#!/bin/bash
set -e

echo "[+] (IPsec Test) Stopping any existing iperf3 server on h2..."
ip netns exec h2 pkill iperf3 2>/dev/null || true

echo "[+] (IPsec Test) Starting iperf3 server in background on h2..."
ip netns exec h2 iperf3 -s -D

echo "[+] (IPsec Test) Starting tcpdump on WAN (wan-gw1) to capture ESP packets..."
ip netns exec wan tcpdump -i wan-gw1 -n esp -w esp_capture.pcap >/dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 1

echo "[+] (IPsec Test) Generating ICMP traffic: h1 pinging h2..."
ip netns exec h1 ping -c 4 10.0.2.2

echo "[+] (IPsec Test) Generating TCP traffic: h1 running iperf3 client against h2..."
ip netns exec h1 iperf3 -c 10.0.2.2 -t 5

echo "[+] (IPsec Test) Stopping tcpdump..."
kill $TCPDUMP_PID
wait $TCPDUMP_PID 2>/dev/null || true
echo "[+] (IPsec Test) IPsec test completed! Capture saved to esp_capture.pcap"