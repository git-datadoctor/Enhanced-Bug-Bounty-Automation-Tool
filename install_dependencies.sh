#!/bin/bash

# Install dependencies for Bug Bounty Automation Tool
# Supports: Ubuntu/Debian, RHEL/CentOS, and Arch Linux

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    else
        OS=$(uname -s)
    fi
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

# Function to install Go
install_go() {
    echo -e "${YELLOW}Installing Go...${NC}"
    if ! command -v go &> /dev/null; then
        case $OS in
            "Ubuntu"|"Debian GNU/Linux")
                apt-get install -y golang
                ;;
            "CentOS Linux"|"Red Hat Enterprise Linux")
                yum install -y golang
                ;;
            "Arch Linux")
                pacman -S --noconfirm go
                ;;
        esac
    else
        echo -e "${GREEN}Go is already installed${NC}"
    fi
}

# Function to install Python dependencies
install_python_deps() {
    echo -e "${YELLOW}Installing Python dependencies...${NC}"
    pip3 install dnspython requests argparse
}

# Function to install system packages
install_system_packages() {
    echo -e "${YELLOW}Installing system packages...${NC}"
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            apt-get update
            apt-get install -y git python3 python3-pip curl wget jq build-essential
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux")
            yum update -y
            yum groupinstall -y "Development Tools"
            yum install -y git python3 python3-pip curl wget jq
            ;;
        "Arch Linux")
            pacman -Syu --noconfirm
            pacman -S --noconfirm git python python-pip curl wget jq base-devel
            ;;
        *)
            echo -e "${RED}Unsupported operating system${NC}"
            exit 1
            ;;
    esac
}

# Function to install Go tools
install_go_tools() {
    echo -e "${YELLOW}Installing Go-based tools...${NC}"
    go_tools=(
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
        "github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
        "github.com/ffuf/ffuf@latest"
        "github.com/tomnomnom/gf@latest"
        "github.com/tomnomnom/assetfinder@latest"
        "github.com/lc/gau@latest"
        "github.com/hakluke/hakrawler@latest"
        "github.com/hahwul/dalfox/v2@latest"
    )

    for tool in "${go_tools[@]}"; do
        echo -e "${YELLOW}Installing $tool...${NC}"
        go install $tool
    done
}

# Function to install additional tools
install_additional_tools() {
    echo -e "${YELLOW}Installing additional tools...${NC}"
    
    # Install Amass
    echo -e "${YELLOW}Installing Amass...${NC}"
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            snap install amass
            ;;
        "CentOS Linux"|"Red Hat Enterprise Linux"|"Arch Linux")
            go install -v github.com/OWASP/Amass/v3/...@master
            ;;
    esac
    
    # Install massdns
    echo -e "${YELLOW}Installing massdns...${NC}"
    git clone https://github.com/blechschmidt/massdns.git
    cd massdns
    make
    cp bin/massdns /usr/local/bin/
    cd ..
    rm -rf massdns
}

# Function to setup wordlists
setup_wordlists() {
    echo -e "${YELLOW}Setting up wordlists...${NC}"
    mkdir -p /usr/share/wordlists
    
    # Download SecLists
    if [ ! -d "/usr/share/wordlists/SecLists" ]; then
        echo -e "${YELLOW}Downloading SecLists...${NC}"
        git clone https://github.com/danielmiessler/SecLists.git /usr/share/wordlists/SecLists
    fi
    
    # Create symlinks for commonly used wordlists
    ln -sf /usr/share/wordlists/SecLists/Discovery/DNS/subdomains-top1million-110000.txt /usr/share/wordlists/subdomains.txt
    ln -sf /usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt /usr/share/wordlists/common.txt
    ln -sf /usr/share/wordlists/SecLists/Discovery/Web-Content/api/params.txt /usr/share/wordlists/params.txt
}

# Main installation function
main() {
    check_root
    detect_os
    
    echo -e "${YELLOW}Installing dependencies for Bug Bounty Automation Tool...${NC}"
    echo -e "${YELLOW}Detected OS: $OS${NC}"
    
    # Install system packages
    install_system_packages
    
    # Install Go
    install_go
    
    # Setup Go environment
    export GOPATH=$HOME/go
    export PATH=$PATH:$GOPATH/bin
    
    # Install Python dependencies
    install_python_deps
    
    # Install Go tools
    install_go_tools
    
    # Install additional tools
    install_additional_tools
    
    # Setup wordlists
    setup_wordlists
    
    echo -e "${GREEN}Installation completed!${NC}"
    echo -e "${YELLOW}Please run ./test_setup.sh to verify the installation${NC}"
}

# Run main function
main
