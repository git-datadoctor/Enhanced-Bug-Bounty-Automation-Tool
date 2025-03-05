#!/bin/bash

# Tool version checker and installer for Bug Bounty Automation Tool
# Checks existing tool versions and only installs/updates if needed

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
FORCE_UPDATE=false
CHECK_ONLY=false
INSTALL_MISSING=true

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -c, --check-only      Only check versions without installing"
    echo "  -f, --force-update    Force update all tools"
    echo "  -s, --skip-install    Skip installation of missing tools"
    echo "  -h, --help           Show this help message"
    echo
    echo "Example:"
    echo "  $0 --check-only"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--check-only)
            CHECK_ONLY=true
            INSTALL_MISSING=false
            shift
            ;;
        -f|--force-update)
            FORCE_UPDATE=true
            shift
            ;;
        -s|--skip-install)
            INSTALL_MISSING=false
            shift
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get tool version
get_version() {
    local tool=$1
    local version_cmd=$2
    local version
    
    if ! check_command "$tool"; then
        echo "not_installed"
        return
    fi
    
    version=$($version_cmd 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
    if [ -z "$version" ]; then
        version="unknown"
    fi
    echo "$version"
}

# Function to check Go installation
check_go() {
    if check_command "go"; then
        local version=$(go version | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?')
        echo -e "${BLUE}Go${NC} - Version: ${GREEN}$version${NC}"
        return 0
    else
        echo -e "${BLUE}Go${NC} - ${RED}Not installed${NC}"
        return 1
    fi
}

# Function to check Python installation
check_python() {
    if check_command "python3"; then
        local version=$(python3 --version 2>&1 | cut -d' ' -f2)
        echo -e "${BLUE}Python3${NC} - Version: ${GREEN}$version${NC}"
        return 0
    else
        echo -e "${BLUE}Python3${NC} - ${RED}Not installed${NC}"
        return 1
    fi
}

# Function to check Go tools
check_go_tool() {
    local tool=$1
    local package=$2
    local version_flag=${3:---version}
    
    if check_command "$tool"; then
        local version=$("$tool" "$version_flag" 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        if [ -n "$version" ]; then
            echo -e "${BLUE}$tool${NC} - Version: ${GREEN}$version${NC}"
        else
            echo -e "${BLUE}$tool${NC} - ${YELLOW}Version unknown${NC}"
        fi
        
        if [ "$FORCE_UPDATE" = true ]; then
            echo -e "${YELLOW}Force updating $tool...${NC}"
            if [ "$CHECK_ONLY" = false ]; then
                go install -v "$package@latest"
            fi
        fi
    else
        echo -e "${BLUE}$tool${NC} - ${RED}Not installed${NC}"
        if [ "$INSTALL_MISSING" = true ] && [ "$CHECK_ONLY" = false ]; then
            echo -e "${YELLOW}Installing $tool...${NC}"
            go install -v "$package@latest"
        fi
    fi
}

# Function to check system package
check_system_package() {
    local tool=$1
    local package=${2:-$1}
    
    if check_command "$tool"; then
        local version=$("$tool" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        if [ -n "$version" ]; then
            echo -e "${BLUE}$tool${NC} - Version: ${GREEN}$version${NC}"
        else
            echo -e "${BLUE}$tool${NC} - ${YELLOW}Version unknown${NC}"
        fi
    else
        echo -e "${BLUE}$tool${NC} - ${RED}Not installed${NC}"
        if [ "$INSTALL_MISSING" = true ] && [ "$CHECK_ONLY" = false ]; then
            echo -e "${YELLOW}Please install $package using your system's package manager${NC}"
        fi
    fi
}

# Function to check Python package
check_python_package() {
    local package=$1
    local module=${2:-$1}
    
    if python3 -c "import $module" 2>/dev/null; then
        local version=$(python3 -c "import $module; print($module.__version__)" 2>/dev/null)
        if [ -n "$version" ]; then
            echo -e "${BLUE}$package${NC} - Version: ${GREEN}$version${NC}"
        else
            echo -e "${BLUE}$package${NC} - ${YELLOW}Version unknown${NC}"
        fi
    else
        echo -e "${BLUE}$package${NC} - ${RED}Not installed${NC}"
        if [ "$INSTALL_MISSING" = true ] && [ "$CHECK_ONLY" = false ]; then
            echo -e "${YELLOW}Installing $package...${NC}"
            pip3 install "$package"
        fi
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Bug Bounty Automation Tool - Tool Version Checker${NC}"
    echo
    
    # Check core requirements
    echo "Core Requirements:"
    echo "----------------"
    check_go
    check_python
    check_system_package "git"
    check_system_package "curl"
    check_system_package "wget"
    check_system_package "jq"
    echo
    
    # Check Go tools
    echo "Go Tools:"
    echo "---------"
    check_go_tool "subfinder" "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    check_go_tool "httpx" "github.com/projectdiscovery/httpx/cmd/httpx"
    check_go_tool "dnsx" "github.com/projectdiscovery/dnsx/cmd/dnsx"
    check_go_tool "ffuf" "github.com/ffuf/ffuf"
    check_go_tool "gf" "github.com/tomnomnom/gf"
    check_go_tool "assetfinder" "github.com/tomnomnom/assetfinder"
    check_go_tool "hakrawler" "github.com/hakluke/hakrawler"
    check_go_tool "dalfox" "github.com/hahwul/dalfox/v2"
    echo
    
    # Check Python packages
    echo "Python Packages:"
    echo "---------------"
    check_python_package "requests"
    check_python_package "dnspython"
    check_python_package "argparse"
    echo
    
    # Check optional tools
    echo "Optional Tools:"
    echo "--------------"
    check_system_package "aws" "awscli"
    check_system_package "shodan"
    check_system_package "censys"
    echo
    
    if [ "$CHECK_ONLY" = true ]; then
        echo -e "${YELLOW}This was a check-only run. No installations were performed.${NC}"
    elif [ "$INSTALL_MISSING" = false ]; then
        echo -e "${YELLOW}Installation of missing tools was skipped.${NC}"
    fi
    
    echo -e "${GREEN}Tool check completed!${NC}"
}

# Run main function
main
