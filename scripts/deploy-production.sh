#!/bin/bash

# DataFish - Production Deployment Script for EC2 Linux
# Run as root or with sudo

set -e

echo "🐟 DataFish - Production Deployment for EC2 Linux"
echo "=================================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root or with sudo"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="/opt/datafish"
APP_USER="datafish"

echo -e "${BLUE}[1/8] Creating application user...${NC}"
if ! id "$APP_USER" &>/dev/null; then
    useradd -r -s /bin/bash -d $INSTALL_DIR $APP_USER
    echo -e "${GREEN}✓ User created${NC}"
else
    echo -e "${YELLOW}User already exists${NC}"
fi

echo -e "\n${BLUE}[2/8] Installing system dependencies...${NC}"

# Detect package manager
if command -v yum &> /dev/null; then
    PKG_MGR="yum"
    yum update -y || true
    yum install -y wget git || true
elif command -v apt-get &> /dev/null; then
    PKG_MGR="apt"
    apt-get update
    apt-get install -y curl wget git
else
    echo "Unsupported package manager"
    exit 1
fi

echo -e "${GREEN}✓ System dependencies installed${NC}"

echo -e "\n${BLUE}[3/8] Installing Go...${NC}"
if ! command -v go &> /dev/null; then
    GO_VERSION="1.21.5"
    cd /tmp
    wget "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin
    rm "go${GO_VERSION}.linux-amd64.tar.gz"
    echo -e "${GREEN}✓ Go installed${NC}"
else
    echo -e "${YELLOW}Go already installed${NC}"
fi

echo -e "\n${BLUE}[4/8] Installing Java...${NC}"
if ! command -v java &> /dev/null; then
    if [ "$PKG_MGR" = "yum" ]; then
        # Try Amazon Corretto first (Amazon Linux 2023)
        yum install -y java-17-amazon-corretto-devel || yum install -y java-17-openjdk java-17-openjdk-devel
    else
        apt-get install -y openjdk-17-jdk
    fi
    echo -e "${GREEN}✓ Java installed${NC}"
else
    echo -e "${YELLOW}Java already installed${NC}"
fi

echo -e "\n${BLUE}[5/8] Installing Maven...${NC}"
if ! command -v mvn &> /dev/null; then
    MAVEN_VERSION="3.9.6"
    cd /tmp
    wget "https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    tar -C /opt -xzf "apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    ln -s "/opt/apache-maven-${MAVEN_VERSION}" /opt/maven
    echo 'export PATH=$PATH:/opt/maven/bin' >> /etc/profile
    export PATH=$PATH:/opt/maven/bin
    rm "apache-maven-${MAVEN_VERSION}-bin.tar.gz"
    echo -e "${GREEN}✓ Maven installed${NC}"
else
    echo -e "${YELLOW}Maven already installed${NC}"
fi

echo -e "\n${BLUE}[6/8] Installing Python...${NC}"
if ! command -v python3 &> /dev/null; then
    if [ "$PKG_MGR" = "yum" ]; then
        yum install -y python3 python3-pip python3-venv
    else
        apt-get install -y python3 python3-pip python3-venv
    fi
    echo -e "${GREEN}✓ Python installed${NC}"
else
    echo -e "${YELLOW}Python already installed${NC}"
fi

echo -e "\n${BLUE}[7/8] Installing Node.js...${NC}"
if ! command -v node &> /dev/null; then
    curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
    if [ "$PKG_MGR" = "yum" ]; then
        yum install -y nodejs
    else
        apt-get install -y nodejs
    fi
    echo -e "${GREEN}✓ Node.js installed${NC}"
else
    echo -e "${YELLOW}Node.js already installed${NC}"
fi

echo -e "\n${BLUE}[8/8] Copying application files...${NC}"
mkdir -p $INSTALL_DIR
cp -r ./* $INSTALL_DIR/
chown -R $APP_USER:$APP_USER $INSTALL_DIR

echo -e "${GREEN}✓ Files copied${NC}"

echo -e "\n${BLUE}Building services...${NC}"

# Build Notification Service
echo "Building Notification Service..."
cd $INSTALL_DIR/notification-service
sudo -u $APP_USER /usr/local/go/bin/go build -o notification-service
echo -e "${GREEN}✓ Notification service built${NC}"

# Build Product Service
echo "Building Product Service..."
cd $INSTALL_DIR/product-service
sudo -u $APP_USER /opt/maven/bin/mvn clean package -DskipTests
echo -e "${GREEN}✓ Product service built${NC}"

# Setup Order Service
echo "Setting up Order Service..."
cd $INSTALL_DIR/order-service
sudo -u $APP_USER python3 -m venv venv
sudo -u $APP_USER venv/bin/pip install -r requirements.txt
echo -e "${GREEN}✓ Order service setup${NC}"

# Setup API Gateway
echo "Setting up API Gateway..."
cd $INSTALL_DIR/api-gateway
sudo -u $APP_USER npm install
echo -e "${GREEN}✓ API Gateway setup${NC}"

# Build Frontend
echo "Building Frontend..."
cd $INSTALL_DIR/frontend
sudo -u $APP_USER npm install
sudo -u $APP_USER npm run build
echo -e "${GREEN}✓ Frontend built${NC}"

echo -e "\n${BLUE}Installing systemd services...${NC}"

# Copy systemd service files
cp $INSTALL_DIR/scripts/systemd/*.service /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable services
systemctl enable datafish-notification
systemctl enable datafish-product
systemctl enable datafish-order
systemctl enable datafish-gateway
systemctl enable datafish-frontend

echo -e "${GREEN}✓ Systemd services installed${NC}"

echo -e "\n${BLUE}Starting services...${NC}"
systemctl start datafish-notification
sleep 2
systemctl start datafish-product
sleep 2
systemctl start datafish-order
sleep 2
systemctl start datafish-gateway
sleep 2
systemctl start datafish-frontend

echo ""
echo -e "${GREEN}=================================================="
echo "✓ DataFish deployed successfully!"
echo "==================================================${NC}"
echo ""
echo "Service Status:"
systemctl status datafish-notification --no-pager | grep Active
systemctl status datafish-product --no-pager | grep Active
systemctl status datafish-order --no-pager | grep Active
systemctl status datafish-gateway --no-pager | grep Active
systemctl status datafish-frontend --no-pager | grep Active
echo ""
echo "Access the application at: http://$(hostname -I | awk '{print $1}'):3000"
echo ""
echo "Useful commands:"
echo "  systemctl status datafish-*          # Check all services"
echo "  systemctl restart datafish-*         # Restart all services"
echo "  journalctl -u datafish-notification -f  # View logs"
echo ""

