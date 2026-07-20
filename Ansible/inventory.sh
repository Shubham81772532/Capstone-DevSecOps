#!/bin/bash
set -e

# Get EC2 Public IP from Terraform
IP=$(cd ../Terraform && terraform output -raw ec2_public_ip 2>/dev/null)

if [ -z "$IP" ]; then
  echo "ERROR: Could not get EC2 IP. Run 'terraform apply' first."
  exit 1
fi

# Generate inventory file
cat > inventory.ini <<EOF
[jenkins]
$IP ansible_user=ubuntu ansible_ssh_private_key_file=/Users/shubham/Downloads/hostar-key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "Inventory generated for IP: $IP"
cat inventory.ini