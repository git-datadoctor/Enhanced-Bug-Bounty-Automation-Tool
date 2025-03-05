#!/bin/bash

# Header analysis script for discovered hosts
# This script will analyze HTTP headers for security configurations and server information

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

OUTPUT_DIR="bug_bounty_results"
HEADERS_DIR="$OUTPUT_DIR/headers"
ANALYSIS_FILE="$OUTPUT_DIR/header_analysis.txt"

# Create directories
mkdir -p "$HEADERS_DIR"

# Live hosts from our scan
HOSTS=(
    "https://certinia.com"
    "https://www.certinia.com"
    "https://blog.certinia.com"
    "https://help.certinia.com"
)

# Function to analyze security headers
analyze_headers() {
    local url=$1
    local domain=$(echo "$url" | cut -d'/' -f3)
    local header_file="$HEADERS_DIR/${domain}_headers.txt"
    
    echo -e "${BLUE}Analyzing headers for $url${NC}"
    
    # Fetch headers with curl
    curl -sI -m 10 -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" "$url" > "$header_file"
    
    # Check important security headers
    {
        echo "Security Analysis for $url"
        echo "=========================="
        echo
        
        # Extract server information
        echo "Server Information:"
        grep -i "server:" "$header_file" || echo "Server: Not disclosed"
        grep -i "x-powered-by:" "$header_file" || echo "X-Powered-By: Not disclosed"
        echo
        
        # Security Headers
        echo "Security Headers:"
        echo "----------------"
        
        # Check for specific security headers
        headers=(
            "Strict-Transport-Security"
            "Content-Security-Policy"
            "X-Frame-Options"
            "X-Content-Type-Options"
            "X-XSS-Protection"
            "Referrer-Policy"
            "Permissions-Policy"
            "Access-Control-Allow-Origin"
        )
        
        for header in "${headers[@]}"; do
            if grep -i "^$header:" "$header_file" > /dev/null; then
                echo -e "${GREEN}[✓]${NC} $header: $(grep -i "^$header:" "$header_file" | cut -d':' -f2-)"
            else
                echo -e "${RED}[✗]${NC} $header: Missing"
            fi
        done
        echo
        
        # Check for cookies and their security flags
        echo "Cookie Analysis:"
        echo "---------------"
        if grep -i "set-cookie:" "$header_file" > /dev/null; then
            grep -i "set-cookie:" "$header_file" | while read -r cookie; do
                echo "Cookie found: $cookie"
                if [[ "$cookie" == *"Secure"* ]]; then
                    echo -e "${GREEN}[✓]${NC} Secure flag set"
                else
                    echo -e "${RED}[✗]${NC} Secure flag not set"
                fi
                if [[ "$cookie" == *"HttpOnly"* ]]; then
                    echo -e "${GREEN}[✓]${NC} HttpOnly flag set"
                else
                    echo -e "${RED}[✗]${NC} HttpOnly flag not set"
                fi
                if [[ "$cookie" == *"SameSite"* ]]; then
                    echo -e "${GREEN}[✓]${NC} SameSite attribute set"
                else
                    echo -e "${RED}[✗]${NC} SameSite attribute not set"
                fi
                echo
            done
        else
            echo "No cookies found"
        fi
        
        echo "----------------------------------------"
        echo
    } >> "$ANALYSIS_FILE"
}

# Main execution
echo "Header Analysis Report" > "$ANALYSIS_FILE"
echo "====================" >> "$ANALYSIS_FILE"
echo "Generated: $(date)" >> "$ANALYSIS_FILE"
echo >> "$ANALYSIS_FILE"

for host in "${HOSTS[@]}"; do
    analyze_headers "$host"
done

echo -e "${GREEN}Analysis completed. Results saved in $ANALYSIS_FILE${NC}"
