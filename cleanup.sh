#!/bin/bash

# Cleanup script for Bug Bounty Automation Tool
# Helps manage old scan results and reports

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
RESULTS_DIR="bug_bounty_results"
REPORTS_DIR="reports"
DAYS_OLD=30
DRY_RUN=false

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -d, --days N          Remove files older than N days (default: 30)"
    echo "  -r, --results-dir DIR  Results directory to clean (default: bug_bounty_results)"
    echo "  -o, --reports-dir DIR  Reports directory to clean (default: reports)"
    echo "  --dry-run             Show what would be deleted without actually deleting"
    echo "  -h, --help            Show this help message"
    echo
    echo "Example:"
    echo "  $0 --days 7 --dry-run"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            DAYS_OLD="$2"
            shift 2
            ;;
        -r|--results-dir)
            RESULTS_DIR="$2"
            shift 2
            ;;
        -o|--reports-dir)
            REPORTS_DIR="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
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

# Function to format file size
format_size() {
    local size=$1
    local units=("B" "KB" "MB" "GB")
    local unit=0
    
    while ((size > 1024 && unit < ${#units[@]}-1)); do
        size=$(echo "scale=2; $size/1024" | bc)
        ((unit++))
    done
    
    printf "%.2f %s" $size "${units[$unit]}"
}

# Function to cleanup directory
cleanup_directory() {
    local dir=$1
    local type=$2
    local total_size=0
    local count=0
    
    echo -e "${BLUE}Scanning $type in $dir...${NC}"
    
    if [ ! -d "$dir" ]; then
        echo -e "${YELLOW}Directory $dir does not exist, skipping...${NC}"
        return
    }
    
    while IFS= read -r file; do
        if [ -z "$file" ]; then continue; fi
        
        local size=$(stat -f %z "$file" 2>/dev/null || stat -c %s "$file" 2>/dev/null)
        total_size=$((total_size + size))
        count=$((count + 1))
        
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}Would delete:${NC} $file ($(format_size $size))"
        else
            echo -e "${RED}Deleting:${NC} $file ($(format_size $size))"
            rm -rf "$file"
        fi
    done < <(find "$dir" -type f -mtime +$DAYS_OLD 2>/dev/null)
    
    if [ $count -gt 0 ]; then
        echo -e "${GREEN}Found $count old $type files ($(format_size $total_size))${NC}"
        if [ "$DRY_RUN" = true ]; then
            echo -e "${YELLOW}Dry run - no files were actually deleted${NC}"
        fi
    else
        echo -e "${GREEN}No old $type files found${NC}"
    fi
}

# Main execution
main() {
    echo -e "${BLUE}Bug Bounty Automation Tool - Cleanup Utility${NC}"
    echo "Cleaning files older than $DAYS_OLD days"
    echo
    
    # Cleanup scan results
    cleanup_directory "$RESULTS_DIR" "scan results"
    echo
    
    # Cleanup reports
    cleanup_directory "$REPORTS_DIR" "reports"
    echo
    
    # Cleanup temporary files
    cleanup_directory "/tmp/bug_bounty_*" "temporary files"
    
    echo -e "${GREEN}Cleanup completed!${NC}"
}

# Run main function
main
