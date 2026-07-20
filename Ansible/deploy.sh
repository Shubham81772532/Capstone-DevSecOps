#!/bin/bash
set -e

echo "======================================"
echo " Hotstar DevSecOps Deployment "
echo "======================================"

# SSH Key
PEM_FILE="/Users/shubham/Downloads/hostar-key.pem"

# Step 1: Generate Inventory
echo ""
echo "[1/4] Generating Inventory..."
./inventory.sh

# Step 2: Get EC2 IP
IP=$(awk 'NR==2 {print $1}' inventory.ini)

echo "EC2 IP: $IP"

# Step 3: Test SSH
echo ""
echo "[2/4] Testing SSH Connection..."

ssh -o StrictHostKeyChecking=no \
    -i "$PEM_FILE" \
    ubuntu@"$IP" \
    "echo 'SSH Connection Successful!'"

# Step 4: Test Ansible
echo ""
echo "[3/4] Testing Ansible Connection..."

ansible all -i inventory.ini -m ping

# Step 5: Run Playbook
echo ""
echo "[4/4] Running Playbook..."

ansible-playbook -i inventory.ini playbook.yml

echo ""
echo "======================================"
echo " Deployment Completed Successfully "
echo "======================================"
echo "Jenkins    : http://$IP:8080"
echo "SonarQube  : http://$IP:9000"