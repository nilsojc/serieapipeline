#!/bin/bash

echo "Setting up AWS CLI..."

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
fi

echo "AWS CLI Installed"

# Pre-configure AWS CLI if needed (e.g., default region or profile)
aws configure set region us-east-1
aws configure set output json

echo "AWS CLI setup complete."

pip install boto3
brew tap aws/tap
brew install aws-sam-cli

sudo wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Download the Docker CLI binary
curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-20.10.9.tgz -o docker.tgz

# Extract the binary
tar -xzf docker.tgz

# Move the Docker CLI binary to a directory in your PATH
sudo mv docker/docker /usr/local/bin/

# Clean up
rm -rf docker docker.tgz
