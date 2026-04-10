#!/bin/bash
chmod +x *.sh

echo "=================================================="
echo "          IPSEC SIMULATION WORKFLOW             "
echo "=================================================="

echo -e "\n---> PHASE 1: Topology Setup"
./setup_topology.sh

echo -e "\n---> PHASE 2: Plaintext Test"
./test_plaintext.sh

echo -e "\n---> PHASE 3: IPsec Setup"
./setup_ipsec.sh

echo -e "\n---> PHASE 4: IPsec Test"
./test_ipsec.sh

echo -e "\n---> PHASE 5: Cleanup"
./cleanup.sh

echo -e "\n=================================================="
echo "          SIMULATION COMPLETE                   "
echo "=================================================="