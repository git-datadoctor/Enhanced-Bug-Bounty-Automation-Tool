#!/bin/bash

# Quick scan script using available tools
# This is a minimal version that works with just curl and httpx

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Target domain
TARGET="certinia.com"
OUTPUT_DIR="bug_bounty_results"
LOG_FILE="$OUTPUT_DIR/quick_scan.log"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to log messages
log_msg() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to check HTTP status
check_http() {
    local domain=$1
    local protocol=$2
    
    log_msg "INFO" "Checking $protocol://$domain"
    
    # Use curl to check the domain
    local response=$(curl -sI -m 10 -w "%{http_code}" -o /dev/null "$protocol://$domain")
    if [ $? -eq 0 ] && [ "$response" != "000" ]; then
        echo -e "${GREEN}[+] $protocol://$domain - HTTP $response${NC}"
        echo "$protocol://$domain - HTTP $response" >> "$OUTPUT_DIR/live_hosts.txt"
        
        # Get headers for additional information
        curl -sI -m 10 "$protocol://$domain" > "$OUTPUT_DIR/${domain}_${protocol}_headers.txt"
    else
        echo -e "${RED}[-] $protocol://$domain - Not responding${NC}"
    fi
}

# Function to check common subdomains
check_common_subdomains() {
    local domain=$1
    local common_subs=("www" "api" "mail" "blog" "dev" "stage" "test" "docs" "support" "help" "app" "portal")
    
    for sub in "${common_subs[@]}"; do
        local subdomain="$sub.$domain"
        check_http "$subdomain" "https"
    done
}

# Main execution
main() {
    log_msg "INFO" "Starting quick scan for $TARGET"
    
    # Create live hosts file
    echo "# Live Hosts - $(date)" > "$OUTPUT_DIR/live_hosts.txt"
    
    # Check main domain
    check_http "$TARGET" "http"
    check_http "$TARGET" "https"
    
    # Check common subdomains
    log_msg "INFO" "Checking common subdomains"
    check_common_subdomains "$TARGET"
    
    # If httpx is available, use it for additional probing
    if command -v httpx &> /dev/null; then
        log_msg "INFO" "Running httpx probe"
        echo "$TARGET" | httpx -silent -title -status-code -tech-detect -o "$OUTPUT_DIR/httpx_results.txt"
    fi
    
    # Generate summary
    {
        echo "Quick Scan Summary"
        echo "=================="
        echo "Target: $TARGET"
        echo "Scan Date: $(date)"
        echo
        echo "Live Hosts:"
        cat "$OUTPUT_DIR/live_hosts.txt"
        
        if [ -f "$OUTPUT_DIR/httpx_results.txt" ]; then
            echo
            echo "HTTPX Results:"
            cat "$OUTPUT_DIR/httpx_results.txt"
        fi
    } > "$OUTPUT_DIR/summary.txt"
    
    log_msg "INFO" "Scan completed. Results saved in $OUTPUT_DIR/"
    log_msg "INFO" "Summary file: $OUTPUT_DIR/summary.txt"
}

# Run main function
main
