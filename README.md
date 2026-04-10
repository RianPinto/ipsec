# IPsec Namespace Simulation

## Files
- `setup_topology.sh` : builds the namespace topology
- `test_plaintext.sh` : validates traffic without IPsec
- `setup_ipsec.sh` : applies ESP tunnel mode using `ip xfrm`
- `test_ipsec.sh` : captures ESP packets on WAN
- `cleanup.sh` : removes all namespaces

## Topology
h1 -> gw1 -> wan -> gw2 -> h2

## Run Order
chmod +x *.sh
sudo su
./main.sh