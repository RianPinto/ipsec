#!/bin/bash
set -e

MODE=${1:-tunnel}
if [[ "$MODE" != "tunnel" && "$MODE" != "transport" ]]; then
    echo "Usage: $0 [tunnel|transport]"
    exit 1
fi

KEY=0x11111111111111111111111111111111
AUTH=0x22222222222222222222222222222222

echo "[+] (IPsec) Setting up IPsec $MODE..."

# 1. Clean up any existing XFRM config on all relevant namespaces
for ns in h1 h2 gw1 gw2; do
    ip netns exec $ns ip xfrm state flush 2>/dev/null || true
    ip netns exec $ns ip xfrm policy flush 2>/dev/null || true
done

if [[ "$MODE" == "tunnel" ]]; then
    # ===========================================================
    # TUNNEL MODE — SAs on gateways (gw1 / gw2)
    #   Outer IP header added: 192.168.x.x wraps inner 10.0.x.x
    #   On the WAN you see: IP 192.168.100.1 > 192.168.200.2: ESP
    # ===========================================================
    echo "[+] (IPsec) Adding SAs on gw1/gw2 (tunnel mode)..."

    # SPI 0x100: gw1 -> gw2
    for ns in gw1 gw2; do
        ip netns exec $ns ip xfrm state add src 192.168.100.1 dst 192.168.200.2 \
            proto esp spi 0x100 mode tunnel \
            enc 'cbc(aes)' $KEY auth 'hmac(md5)' $AUTH
    done
    # SPI 0x200: gw2 -> gw1
    for ns in gw1 gw2; do
        ip netns exec $ns ip xfrm state add src 192.168.200.2 dst 192.168.100.1 \
            proto esp spi 0x200 mode tunnel \
            enc 'cbc(aes)' $KEY auth 'hmac(md5)' $AUTH
    done

    echo "[+] (IPsec) Adding Policies on gw1/gw2 (tunnel mode)..."

    # gw1 policies
    ip netns exec gw1 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir out \
        tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel
    ip netns exec gw1 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir in \
        tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel
    ip netns exec gw1 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir fwd \
        tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel

    # gw2 policies
    ip netns exec gw2 ip xfrm policy add src 10.0.2.0/24 dst 10.0.1.0/24 dir out \
        tmpl src 192.168.200.2 dst 192.168.100.1 proto esp mode tunnel
    ip netns exec gw2 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir in \
        tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel
    ip netns exec gw2 ip xfrm policy add src 10.0.1.0/24 dst 10.0.2.0/24 dir fwd \
        tmpl src 192.168.100.1 dst 192.168.200.2 proto esp mode tunnel

else
    # ===========================================================
    # TRANSPORT MODE — SAs on hosts (h1 / h2)
    #   No outer header: original 10.0.x.x IPs stay visible
    #   On the WAN you see: IP 10.0.1.2 > 10.0.2.2: ESP
    #   Transport mode only encrypts locally-generated traffic,
    #   so SAs MUST be on the endpoints themselves (h1 and h2).
    # ===========================================================
    echo "[+] (IPsec) Adding SAs on h1/h2 (transport mode)..."

    # SPI 0x100: h1 -> h2
    for ns in h1 h2; do
        ip netns exec $ns ip xfrm state add src 10.0.1.2 dst 10.0.2.2 \
            proto esp spi 0x100 mode transport \
            enc 'cbc(aes)' $KEY auth 'hmac(md5)' $AUTH
    done
    # SPI 0x200: h2 -> h1
    for ns in h1 h2; do
        ip netns exec $ns ip xfrm state add src 10.0.2.2 dst 10.0.1.2 \
            proto esp spi 0x200 mode transport \
            enc 'cbc(aes)' $KEY auth 'hmac(md5)' $AUTH
    done

    echo "[+] (IPsec) Adding Policies on h1/h2 (transport mode)..."

    # h1 policies
    ip netns exec h1 ip xfrm policy add src 10.0.1.2/32 dst 10.0.2.2/32 dir out \
        tmpl src 10.0.1.2 dst 10.0.2.2 proto esp mode transport
    ip netns exec h1 ip xfrm policy add src 10.0.2.2/32 dst 10.0.1.2/32 dir in \
        tmpl src 10.0.2.2 dst 10.0.1.2 proto esp mode transport

    # h2 policies
    ip netns exec h2 ip xfrm policy add src 10.0.2.2/32 dst 10.0.1.2/32 dir out \
        tmpl src 10.0.2.2 dst 10.0.1.2 proto esp mode transport
    ip netns exec h2 ip xfrm policy add src 10.0.1.2/32 dst 10.0.2.2/32 dir in \
        tmpl src 10.0.1.2 dst 10.0.2.2 proto esp mode transport
fi

echo "[+] (IPsec) IPsec $MODE successfully configured!"