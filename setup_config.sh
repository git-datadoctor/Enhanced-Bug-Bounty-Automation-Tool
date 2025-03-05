#!/bin/bash

# Setup script to generate config.ini from template
# This script helps users create their initial configuration file

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to prompt for user input with default value
prompt_with_default() {
    local prompt=$1
    local default=$2
    local value
    
    echo -en "${BLUE}$prompt ${YELLOW}[$default]${NC}: "
    read value
    echo "${value:-$default}"
}

# Function to prompt for sensitive input (no echo)
prompt_sensitive() {
    local prompt=$1
    local value
    
    echo -en "${BLUE}$prompt${NC}: "
    read -s value
    echo
    echo "$value"
}

# Function to validate directory path
validate_directory() {
    local dir=$1
    if [[ ! -d "$dir" ]]; then
        echo -e "${YELLOW}Directory $dir does not exist. Create it? [Y/n]${NC}"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])*$ ]]; then
            mkdir -p "$dir"
            echo -e "${GREEN}Created directory: $dir${NC}"
        else
            echo -e "${RED}Please provide a valid directory path${NC}"
            return 1
        fi
    fi
    return 0
}

# Check if config.ini already exists
if [ -f "config.ini" ]; then
    echo -e "${YELLOW}config.ini already exists. What would you like to do?${NC}"
    echo "1. Create new configuration (backup existing)"
    echo "2. Edit existing configuration"
    echo "3. Exit"
    read -p "Select an option [1-3]: " choice
    
    case $choice in
        1)
            mv config.ini "config.ini.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${GREEN}Existing config.ini backed up${NC}"
            ;;
        2)
            ${EDITOR:-nano} config.ini
            exit 0
            ;;
        3)
            echo -e "${YELLOW}Setup cancelled${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            exit 1
            ;;
    esac
fi

# Check if config.ini.example exists
if [ ! -f "config.ini.example" ]; then
    echo -e "${RED}Error: config.ini.example not found${NC}"
    exit 1
fi

echo -e "${GREEN}Bug Bounty Automation Tool - Configuration Setup${NC}"
echo "This script will help you create a basic configuration file."
echo "Press Enter to accept default values or input your own."
echo

# Gather basic configuration
echo -e "${BLUE}Basic Configuration${NC}"
echo "-------------------"
OUTPUT_DIR=$(prompt_with_default "Output directory for results" "bug_bounty_results")
validate_directory "$OUTPUT_DIR"

WORDLIST=$(prompt_with_default "Path to subdomain wordlist" "/usr/share/wordlists/subdomains.txt")
THREADS=$(prompt_with_default "Number of threads for scanning" "50")
PARALLEL_SCANS=$(prompt_with_default "Number of parallel scans for batch processing" "2")
DELAY_BETWEEN_SCANS=$(prompt_with_default "Delay between scans (seconds)" "30")

echo
echo -e "${BLUE}API Configuration${NC}"
echo "-----------------"
echo -e "${YELLOW}(Leave blank if not available)${NC}"
GITHUB_TOKEN=$(prompt_sensitive "GitHub API Token")
SHODAN_API_KEY=$(prompt_sensitive "Shodan API Key")

echo
echo -e "${BLUE}Feature Configuration${NC}"
echo "--------------------"
ENABLE_JS_ANALYSIS=$(prompt_with_default "Enable JavaScript analysis? (true/false)" "true")
ENABLE_SCREENSHOTS=$(prompt_with_default "Enable screenshots? (true/false)" "true")
ENABLE_CLOUD_ENUM=$(prompt_with_default "Enable cloud enumeration? (true/false)" "true")

echo
echo -e "${BLUE}Scanning Configuration${NC}"
echo "---------------------"
HTTP_PORTS=$(prompt_with_default "HTTP ports to scan (comma-separated)" "80,443,8080,8443")
DNS_RESOLVERS=$(prompt_with_default "DNS resolvers (comma-separated)" "1.1.1.1,8.8.8.8,8.8.4.4")
REQUESTS_PER_SECOND=$(prompt_with_default "Maximum requests per second" "10")

# Generate config.ini
echo
echo -e "${YELLOW}Generating configuration file...${NC}"

cat > config.ini << EOL
[DEFAULT]
# Output directory
OUTPUT_DIR = $OUTPUT_DIR

# Wordlists and resolvers
WORDLIST = $WORDLIST
DNS_RESOLVERS = $DNS_RESOLVERS

# API Keys
GITHUB_TOKEN = $GITHUB_TOKEN
SHODAN_API_KEY = $SHODAN_API_KEY

# Scanning parameters
THREADS = $THREADS
HTTP_PORTS = $HTTP_PORTS
REQUESTS_PER_SECOND = $REQUESTS_PER_SECOND

# Feature flags
ENABLE_JS_ANALYSIS = $ENABLE_JS_ANALYSIS
ENABLE_SCREENSHOTS = $ENABLE_SCREENSHOTS
ENABLE_CLOUD_ENUM = $ENABLE_CLOUD_ENUM

# Batch scanning settings
PARALLEL_SCANS = $PARALLEL_SCANS
DELAY_BETWEEN_SCANS = $DELAY_BETWEEN_SCANS

# Additional settings from template
$(grep -v "^#\|^$\|^GITHUB_TOKEN\|^SHODAN_API_KEY\|^OUTPUT_DIR\|^WORDLIST\|^THREADS\|^HTTP_PORTS\|^DNS_RESOLVERS\|^ENABLE_" config.ini.example)
EOL

echo -e "${GREEN}Configuration file generated successfully!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review and customize config.ini if needed"
echo "2. Run ./test_setup.sh to verify your setup"
echo "3. Start scanning with ./bug_bounty.sh"
echo
echo -e "${BLUE}For more information, refer to the README.md file${NC}"
