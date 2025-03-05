#!/bin/bash

# Report generation script for Bug Bounty Automation Tool
# Generates formatted reports from scan results

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESULTS_DIR="bug_bounty_results"
OUTPUT_DIR="reports"
REPORT_FORMAT="html"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -d, --directory DIR    Source directory containing scan results (default: bug_bounty_results)"
    echo "  -o, --output DIR       Output directory for reports (default: reports)"
    echo "  -f, --format FORMAT    Report format: html,json,md (default: html)"
    echo "  -t, --target DOMAIN    Target domain for the report"
    echo "  -h, --help            Show this help message"
    echo
    echo "Example:"
    echo "  $0 --directory bug_bounty_results --format html,json --target example.com"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            RESULTS_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -f|--format)
            REPORT_FORMAT="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
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

# Validate input directory
if [ ! -d "$RESULTS_DIR" ]; then
    echo -e "${RED}Error: Results directory not found: $RESULTS_DIR${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to generate JSON report
generate_json_report() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_report_${TIMESTAMP}.json"
    
    echo -e "${BLUE}Generating JSON report...${NC}"
    
    # Create JSON structure
    {
        echo "{"
        echo "  \"target\": \"$target\","
        echo "  \"scan_date\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," 
        echo "  \"subdomains\": {"
        if [ -f "$RESULTS_DIR/subdomains/all_subdomains.txt" ]; then
            echo "    \"total\": $(wc -l < "$RESULTS_DIR/subdomains/all_subdomains.txt"),"
            echo "    \"list\": ["
            while IFS= read -r subdomain; do
                echo "      \"$subdomain\","
            done < "$RESULTS_DIR/subdomains/all_subdomains.txt" | sed '$ s/,$//'
            echo "    ]"
        else
            echo "    \"total\": 0,"
            echo "    \"list\": []"
        fi
        echo "  },"
        
        # Add vulnerability findings
        echo "  \"vulnerabilities\": {"
        if [ -d "$RESULTS_DIR/vulns" ]; then
            for vuln_file in "$RESULTS_DIR/vulns"/*_results.txt; do
                if [ -f "$vuln_file" ]; then
                    vuln_type=$(basename "$vuln_file" _results.txt)
                    echo "    \"$vuln_type\": ["
                    while IFS= read -r finding; do
                        echo "      \"$finding\","
                    done < "$vuln_file" | sed '$ s/,$//'
                    echo "    ],"
                fi
            done | sed '$ s/,$//'
        fi
        echo "  }"
        echo "}"
    } > "$output_file"
    
    echo -e "${GREEN}JSON report generated: $output_file${NC}"
}

# Function to generate HTML report
generate_html_report() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_report_${TIMESTAMP}.html"
    
    echo -e "${BLUE}Generating HTML report...${NC}"
    
    # Create HTML structure
    {
        cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bug Bounty Report - $target</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
        }
        .finding {
            margin: 10px 0;
            padding: 10px;
            background-color: #fff;
            border-left: 4px solid #3498db;
        }
        .vulnerability {
            border-left-color: #e74c3c;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-box {
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Bug Bounty Scan Report</h1>
        <div class="section">
            <h2>Scan Information</h2>
            <div class="stats">
                <div class="stat-box">
                    <h3>Target</h3>
                    <p>$target</p>
                </div>
                <div class="stat-box">
                    <h3>Scan Date</h3>
                    <p>$(date)</p>
                </div>
EOF
        
        # Add subdomain statistics
        if [ -f "$RESULTS_DIR/subdomains/all_subdomains.txt" ]; then
            echo "<div class=\"stat-box\">"
            echo "<h3>Total Subdomains</h3>"
            echo "<p>$(wc -l < "$RESULTS_DIR/subdomains/all_subdomains.txt")</p>"
            echo "</div>"
        fi
        
        # Close stats div
        echo "</div></div>"
        
        # Add subdomains section
        echo "<div class=\"section\">"
        echo "<h2>Discovered Subdomains</h2>"
        if [ -f "$RESULTS_DIR/subdomains/all_subdomains.txt" ]; then
            while IFS= read -r subdomain; do
                echo "<div class=\"finding\">$subdomain</div>"
            done < "$RESULTS_DIR/subdomains/all_subdomains.txt"
        else
            echo "<p>No subdomains discovered</p>"
        fi
        echo "</div>"
        
        # Add vulnerabilities section
        echo "<div class=\"section\">"
        echo "<h2>Vulnerabilities</h2>"
        if [ -d "$RESULTS_DIR/vulns" ]; then
            for vuln_file in "$RESULTS_DIR/vulns"/*_results.txt; do
                if [ -f "$vuln_file" ]; then
                    vuln_type=$(basename "$vuln_file" _results.txt)
                    echo "<h3>$(echo "$vuln_type" | tr '[:lower:]' '[:upper:]')</h3>"
                    while IFS= read -r finding; do
                        echo "<div class=\"finding vulnerability\">$finding</div>"
                    done < "$vuln_file"
                fi
            done
        else
            echo "<p>No vulnerabilities found</p>"
        fi
        echo "</div>"
        
        # Close HTML
        echo "</div></body></html>"
    } > "$output_file"
    
    echo -e "${GREEN}HTML report generated: $output_file${NC}"
}

# Function to generate Markdown report
generate_markdown_report() {
    local target=$1
    local output_file="$OUTPUT_DIR/${target}_report_${TIMESTAMP}.md"
    
    echo -e "${BLUE}Generating Markdown report...${NC}"
    
    {
        echo "# Bug Bounty Scan Report"
        echo
        echo "## Scan Information"
        echo
        echo "- **Target:** $target"
        echo "- **Scan Date:** $(date)"
        if [ -f "$RESULTS_DIR/subdomains/all_subdomains.txt" ]; then
            echo "- **Total Subdomains:** $(wc -l < "$RESULTS_DIR/subdomains/all_subdomains.txt")"
        fi
        echo
        
        # Add subdomains section
        echo "## Discovered Subdomains"
        echo
        if [ -f "$RESULTS_DIR/subdomains/all_subdomains.txt" ]; then
            while IFS= read -r subdomain; do
                echo "- $subdomain"
            done < "$RESULTS_DIR/subdomains/all_subdomains.txt"
        else
            echo "No subdomains discovered"
        fi
        echo
        
        # Add vulnerabilities section
        echo "## Vulnerabilities"
        echo
        if [ -d "$RESULTS_DIR/vulns" ]; then
            for vuln_file in "$RESULTS_DIR/vulns"/*_results.txt; do
                if [ -f "$vuln_file" ]; then
                    vuln_type=$(basename "$vuln_file" _results.txt)
                    echo "### $(echo "$vuln_type" | tr '[:lower:]' '[:upper:]')"
                    echo
                    while IFS= read -r finding; do
                        echo "- $finding"
                    done < "$vuln_file"
                    echo
                fi
            done
        else
            echo "No vulnerabilities found"
        fi
    } > "$output_file"
    
    echo -e "${GREEN}Markdown report generated: $output_file${NC}"
}

# Main execution
main() {
    if [ -z "$TARGET" ]; then
        echo -e "${RED}Error: Target domain is required${NC}"
        show_help
    fi
    
    echo -e "${BLUE}Generating reports for $TARGET${NC}"
    
    # Generate reports based on specified formats
    IFS=',' read -ra FORMATS <<< "$REPORT_FORMAT"
    for format in "${FORMATS[@]}"; do
        case $format in
            html)
                generate_html_report "$TARGET"
                ;;
            json)
                generate_json_report "$TARGET"
                ;;
            md)
                generate_markdown_report "$TARGET"
                ;;
            *)
                echo -e "${RED}Unsupported format: $format${NC}"
                ;;
        esac
    done
    
    echo -e "${GREEN}Report generation completed!${NC}"
    echo -e "${BLUE}Reports are available in: $OUTPUT_DIR${NC}"
}

# Run main function
main
