#!/bin/bash

# DataFish Remote Deployment Script
# This script runs on the EC2 instance

set -e

echo "🐟 DataFish - Remote Deployment Script"
echo "======================================="

# Extract the archive
echo "Extracting DataFish..."
cd ~
tar -xzf DataFish.tar.gz
cd DataFish

# Make scripts executable
chmod +x scripts/*.sh

# Run the production deployment
echo "Running production deployment..."
sudo ./scripts/deploy-production.sh

echo ""
echo "======================================="
echo "✅ Deployment complete!"
echo "======================================="
echo ""
echo "Access your application at:"
echo "  http://$(curl -s http://169.254.169.254/latest/meta-data/public-hostname):3000"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status datafish-*"
echo "  sudo journalctl -u datafish-notification -f"
echo ""

