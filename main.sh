#!/bin/bash
chmod +x *.sh

echo "=================================================="
echo "          IPSEC SIMULATION WORKFLOW             "
echo "=================================================="

echo -e "\n---> PHASE 1: Topology Setup"
./setup_topology.sh

echo -e "\n---> PHASE 2: Plaintext Test"
./test_plaintext.sh

echo -e "\n---> PHASE 3: Cleanup"
./cleanup.sh
./setup_topology.sh

echo -e "\n---> PHASE 3: IPsec Setup Transport Mode"
./setup_ipsec.sh transport

echo -e "\n---> PHASE 4: IPsec Test Transport Mode"
./test_ipsec.sh transport

echo -e "\n---> PHASE 3: Cleanup"
./cleanup.sh
./setup_topology.sh

echo -e "\n---> PHASE 5: IPsec Setup Tunnel Mode"
./setup_ipsec.sh tunnel

echo -e "\n---> PHASE 6: IPsec Test Tunnel Mode"
./test_ipsec.sh tunnel

echo -e "\n---> PHASE 7: Cleanup"
./cleanup.sh

echo -e "\n=================================================="
echo "          SIMULATION COMPLETE                   "
echo "=================================================="