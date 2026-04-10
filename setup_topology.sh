#!/bin/bash
set -e

echo "[+] Setting up namespaces: h1, gw1, wan, gw2, h2..."
for ns in h1 gw1 wan gw2 h2; do
    ip netns add $ns
    ip -n $ns link set lo up
done

echo "[+] Creating veth pairs for topology..."
ip link add h1-gw1 type veth peer name gw1-h1
ip link add gw1-wan type veth peer name wan-gw1
ip link add wan-gw2 type veth peer name gw2-wan
ip link add gw2-h2 type veth peer name h2-gw2

echo "[+] Assigning interfaces to namespaces..."
ip link set h1-gw1 netns h1
ip link set gw1-h1 netns gw1
ip link set gw1-wan netns gw1
ip link set wan-gw1 netns wan
ip link set wan-gw2 netns wan
ip link set gw2-wan netns gw2
ip link set gw2-h2 netns gw2
ip link set h2-gw2 netns h2

echo "[+] Configuring IP addresses..."
ip -n h1 addr add 10.0.1.2/24 dev h1-gw1
ip -n gw1 addr add 10.0.1.1/24 dev gw1-h1
ip -n gw1 addr add 192.168.100.1/24 dev gw1-wan
ip -n wan addr add 192.168.100.2/24 dev wan-gw1
ip -n wan addr add 192.168.200.1/24 dev wan-gw2
ip -n gw2 addr add 192.168.200.2/24 dev gw2-wan
ip -n gw2 addr add 10.0.2.1/24 dev gw2-h2
ip -n h2 addr add 10.0.2.2/24 dev h2-gw2

echo "[+] Bringing interfaces UP..."
for i in h1-gw1 gw1-h1 gw1-wan wan-gw1 wan-gw2 gw2-wan gw2-h2 h2-gw2; do
    ns=$(echo $i | cut -d- -f1)
    ip -n $ns link set $i up || true
done

echo "[+] Adding routing entries..."
ip -n h1 route add default via 10.0.1.1
ip -n h2 route add default via 10.0.2.1
ip -n gw1 route add 10.0.2.0/24 via 192.168.100.2
ip -n wan route add 10.0.1.0/24 via 192.168.100.1
ip -n wan route add 10.0.2.0/24 via 192.168.200.2
ip -n gw2 route add 10.0.1.0/24 via 192.168.200.1
ip -n gw1 route add 192.168.200.0/24 via 192.168.100.2
ip -n gw2 route add 192.168.100.0/24 via 192.168.200.1

echo "[+] Enabling IPv4 forwarding on gateways and WAN..."
ip netns exec gw1 sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec wan sysctl -w net.ipv4.ip_forward=1 >/dev/null
ip netns exec gw2 sysctl -w net.ipv4.ip_forward=1 >/dev/null

echo "[+] Topology setup COMPLETED!"
