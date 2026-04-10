#!/bin/bash
set -e

# AES-128 key (16 bytes = 32 hex chars) and HMAC-MD5 auth key (16 bytes)
KEY=0x11111111111111111111111111111111
AUTH=0x22222222222222222222222222222222

echo "[+] (IPsec) Setting up IPsec tunnel between gw1 and gw2..."

# ------------------------------------------------------------
# SPI 0x100: gw1 -> gw2 direction (gw1 encrypts, gw2 decrypts)
#   - gw1 needs this SA as OUTBOUND (src=gw1, dst=gw2)
#   - gw2 needs this SA as INBOUND  (src=gw1, dst=gw2) -- same SA, same SPI
# ------------------------------------------------------------
echo "[+] (IPsec) SPI 0x100 — gw1-to-gw2 SA (gw1 outbound / gw2 inbound)..."
ip netns exec gw1 ip xfrm state add src 192.168.100.1 dst 192.168.200.2 \
    proto esp spi 0x100 mode tunnel \
    enc 'cbc(aes)' $KEY \
    auth 'hmac(md5)' $AUTH

ip netns exec gw2 ip xfrm state add src 192.168.100.1 dst 192.168.200.2 \
    proto esp spi 0x100 mode tunnel \
    enc 'cbc(aes)' $KEY \
    auth 'hmac(md5)' $AUTH

# ------------------------------------------------------------
# SPI 0x200: gw2 -> gw1 direction (gw2 encrypts, gw1 decrypts)
#   - gw2 needs this SA as OUTBOUND (src=gw2, dst=gw1)
#   - gw1 needs this SA as INBOUND  (src=gw2, dst=gw1) -- same SA, same SPI
# ------------------------------------------------------------
echo "[+] (IPsec) SPI 0x200 — gw2-to-gw1 SA (gw2 outbound / gw1 inbound)..."
ip netns exec gw2 ip xfrm state add src 192.168.200.2 dst 192.168.100.1 \
    proto esp spi 0x200 mode tunnel \
    enc 'cbc(aes)' $KEY \
    auth 'hmac(md5)' $AUTH

ip netns exec gw1 ip xfrm state add src 192.168.200.2 dst 192.168.100.1 \
    proto esp spi 0x200 mode tunnel \
    enc 'cbc(aes)' $KEY \
    auth 'hmac(md5)' $AUTH

# ------------------------------------------------------------
# XFRM Policies on gw1
#   out : traffic from LAN1 -> LAN2 must be ESP-encrypted
#   in  : incoming ESP from gw2 for LAN1 traffic must be decrypted
#   fwd : after decryption, forward decrypted packets toward LAN1
# ------------------------------------------------------------
echo "[+] (IPsec) Configuring XFRM Policies on gw1..."
ip netns exec gw1 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir out \
    tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel
ip netns exec gw1 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir in \
    tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel
ip netns exec gw1 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir fwd \
    tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel

# ------------------------------------------------------------
# XFRM Policies on gw2
#   out : traffic from LAN2 -> LAN1 must be ESP-encrypted
#   in  : incoming ESP from gw1 must be decrypted
#   fwd : after decryption, forward decrypted packets toward LAN2
# ------------------------------------------------------------
echo "[+] (IPsec) Configuring XFRM Policies on gw2..."
ip netns exec gw2 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir out \
    tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel
ip netns exec gw2 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir in \
    tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel
ip netns exec gw2 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir fwd \
    tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel

echo "[+] (IPsec) IPsec tunnel successfully configured!"