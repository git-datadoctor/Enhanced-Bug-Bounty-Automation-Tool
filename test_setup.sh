#!/bin/bash

# Test Setup Script for Bug Bounty Automation Tool
# This script verifies the installation and configuration of required tools

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if a command exists
check_tool() {
    local tool=$1
    local required=$2
    
    echo -n "Checking for $tool... "
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}Found${NC}"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}Not found (Required)${NC}"
            return 1
        else
            echo -e "${YELLOW}Not found (Optional)${NC}"
            return 0
        fi
    fi
}

# Function to check configuration file
check_config() {
    echo -n "Checking config.ini... "
    if [ -f "config.ini" ]; then
        echo -e "${GREEN}Found${NC}"
        
        # Check for required fields
        local missing=0
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key// }" ]] && continue
            
            # Check if value is empty or default
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ $value == "YOUR_GITHUB_TOKEN_HERE" ]] || [[ -z "$value" ]]; then
                echo -e "${YELLOW}Warning: $key needs to be configured${NC}"
                missing=1
            fi
        done < "config.ini"
        
        [ $missing -eq 1 ] && echo -e "${YELLOW}Some configuration values need to be updated${NC}"
    else
        echo -e "${RED}Not found${NC}"
        echo -e "${YELLOW}Please copy config.ini.example to config.ini and configure it${NC}"
        return 1
    fi
}

# Function to check wordlists
check_wordlist() {
    local wordlist=$1
    echo -n "Checking wordlist $wordlist... "
    if [ -f "$wordlist" ]; then
        echo -e "${GREEN}Found${NC}"
        return 0
    else
        echo -e "${RED}Not found${NC}"
        return 1
    fi
}

# Main test function
main() {
    echo "Testing Bug Bounty Automation Tool Setup"
    echo "========================================"
    echo
    
    local exit_code=0
    
    # Check required tools
    echo "Checking required tools:"
    echo "----------------------"
    required_tools=("curl" "jq" "subfinder" "amass" "dnsx" "ffuf" "httpx" "gf" "dalfox")
    for tool in "${required_tools[@]}"; do
        check_tool "$tool" "required" || exit_code=1
    done
    echo
    
    # Check optional tools
    echo "Checking optional tools:"
    echo "----------------------"
    optional_tools=("cloud_enum" "aws" "feroxbuster" "dirsearch" "shodan" "censys" "subscraper" "xnLinkFinder" "GitDorker")
    for tool in "${optional_tools[@]}"; do
        check_tool "$tool" "optional"
    done
    echo
    
    # Check configuration
    echo "Checking configuration:"
    echo "---------------------"
    check_config || exit_code=1
    echo
    
    # Check wordlists from config
    echo "Checking wordlists:"
    echo "-----------------"
    if [ -f "config.ini" ]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z "${key// }" ]] && continue
            
            # Check wordlist paths
            if [[ $key == *"WORDLIST"* ]]; then
                value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                check_wordlist "$value" || exit_code=1
            fi
        done < "config.ini"
    fi
    echo
    
    # Check script permissions
    echo "Checking script permissions:"
    echo "-------------------------"
    echo -n "Checking bug_bounty.sh permissions... "
    if [ -x "bug_bounty.sh" ]; then
        echo -e "${GREEN}Executable${NC}"
    else
        echo -e "${RED}Not executable${NC}"
        echo "Run: chmod +x bug_bounty.sh"
        exit_code=1
    fi
    echo
    
    # Final status
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}All required components are properly configured!${NC}"
        echo "You can now run: ./bug_bounty.sh <target_domain>"
    else
        echo -e "${RED}Some components need attention before running the tool${NC}"
        echo "Please address the issues above before running the tool"
    fi
    
    return $exit_code
}

# Run main function
main
