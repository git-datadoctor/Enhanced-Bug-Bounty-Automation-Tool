#!/bin/bash

# Batch scanning script for bug bounty automation
# This script reads targets from targets.txt and runs bug_bounty.sh for each target

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PARALLEL_SCANS=1
DELAY_BETWEEN_SCANS=0
RESUME_FILE=".scan_progress"
LOG_DIR="batch_logs"
TARGETS_FILE="targets.txt"

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -p, --parallel N        Run N scans in parallel (default: 1)"
    echo "  -d, --delay N          Delay N seconds between scans (default: 0)"
    echo "  -r, --resume           Resume from last scan position"
    echo "  -t, --targets FILE     Use specific targets file (default: targets.txt)"
    echo "  -h, --help            Show this help message"
    echo
    echo "Example:"
    echo "  $0 --parallel 2 --delay 30 --resume"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--parallel)
            PARALLEL_SCANS="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY_BETWEEN_SCANS="$2"
            shift 2
            ;;
        -r|--resume)
            RESUME=true
            shift
            ;;
        -t|--targets)
            TARGETS_FILE="$2"
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

# Validate parallel scans number
if ! [[ "$PARALLEL_SCANS" =~ ^[0-9]+$ ]] || [ "$PARALLEL_SCANS" -lt 1 ]; then
    echo -e "${RED}Error: Invalid number of parallel scans${NC}"
    exit 1
fi

# Create necessary directories
mkdir -p "$LOG_DIR"

# Function to log messages
log_msg() {
    local level=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "[$timestamp] [$level] $message"
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/batch_scan.log"
}

# Function to get total targets count
get_total_targets() {
    grep -v '^#' "$TARGETS_FILE" | grep -v '^[[:space:]]*$' | wc -l
}

# Function to get current progress
get_progress() {
    if [ -f "$RESUME_FILE" ]; then
        cat "$RESUME_FILE"
    else
        echo "0"
    fi
}

# Function to update progress
update_progress() {
    echo "$1" > "$RESUME_FILE"
}

# Function to run scan for a single target
run_scan() {
    local target=$1
    local scope=$2
    local program=$3
    local index=$4
    local total=$5
    
    local target_log="$LOG_DIR/${target}_$(date +%Y%m%d_%H%M%S).log"
    
    log_msg "INFO" "[$index/$total] Starting scan for $target ($program)"
    
    # Create target-specific configuration
    local target_config="$LOG_DIR/${target}_config.ini"
    cp config.ini "$target_config"
    echo "TARGET = $target" >> "$target_config"
    echo "SCOPE = $scope" >> "$target_config"
    echo "PROGRAM = $program" >> "$target_config"
    
    # Run the main bug bounty script
    if ./bug_bounty.sh "$target" --config "$target_config" > "$target_log" 2>&1; then
        log_msg "SUCCESS" "[$index/$total] Completed scan for $target"
        return 0
    else
        log_msg "ERROR" "[$index/$total] Failed scan for $target"
        return 1
    fi
}

# Function to display progress bar
show_progress() {
    local current=$1
    local total=$2
    local percentage=$((current * 100 / total))
    local filled=$((percentage / 2))
    local unfilled=$((50 - filled))
    
    printf "\rProgress: ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${unfilled}s" | tr ' ' ' '
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# Main execution
main() {
    # Check if targets file exists
    if [ ! -f "$TARGETS_FILE" ]; then
        log_msg "ERROR" "Targets file $TARGETS_FILE not found"
        exit 1
    fi
    
    # Check if bug_bounty.sh exists and is executable
    if [ ! -x "bug_bounty.sh" ]; then
        log_msg "ERROR" "bug_bounty.sh not found or not executable"
        exit 1
    fi
    
    local total_targets=$(get_total_targets)
    local current_progress=$(get_progress)
    
    log_msg "INFO" "Starting batch scan with $PARALLEL_SCANS parallel scans"
    log_msg "INFO" "Total targets: $total_targets"
    
    if [ "$RESUME" = true ] && [ "$current_progress" -gt 0 ]; then
        log_msg "INFO" "Resuming from target $current_progress"
    else
        current_progress=0
    fi
    
    # Process targets
    local index=$current_progress
    local running=0
    declare -A pids
    
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z "${line// }" ]] && continue
        
        # Parse line
        read -r target scope program <<< "$line"
        
        # Skip already processed targets when resuming
        ((index++))
        if [ "$RESUME" = true ] && [ "$index" -le "$current_progress" ]; then
            continue
        fi
        
        # Wait if we've reached maximum parallel scans
        while [ ${#pids[@]} -ge "$PARALLEL_SCANS" ]; do
            for pid in "${!pids[@]}"; do
                if ! kill -0 "$pid" 2>/dev/null; then
                    wait "$pid"
                    local status=$?
                    if [ $status -eq 0 ]; then
                        log_msg "SUCCESS" "Completed scan for ${pids[$pid]}"
                    else
                        log_msg "ERROR" "Failed scan for ${pids[$pid]}"
                    fi
                    unset pids[$pid]
                fi
            done
            sleep 1
        done
        
        # Start new scan
        run_scan "$target" "$scope" "$program" "$index" "$total_targets" &
        local pid=$!
        pids[$pid]=$target
        
        # Update progress
        update_progress "$index"
        show_progress "$index" "$total_targets"
        
        # Delay between scans if specified
        if [ "$DELAY_BETWEEN_SCANS" -gt 0 ]; then
            sleep "$DELAY_BETWEEN_SCANS"
        fi
        
    done < "$TARGETS_FILE"
    
    # Wait for remaining scans to complete
    for pid in "${!pids[@]}"; do
        wait "$pid"
        local status=$?
        if [ $status -eq 0 ]; then
            log_msg "SUCCESS" "Completed scan for ${pids[$pid]}"
        else
            log_msg "ERROR" "Failed scan for ${pids[$pid]}"
        fi
    done
    
    echo
    log_msg "INFO" "Batch scan completed"
    
    # Clean up progress file
    rm -f "$RESUME_FILE"
}

# Trap ctrl-c
trap 'echo -e "\n${YELLOW}Batch scan interrupted. Run with --resume to continue from last position${NC}"; exit 130' INT

# Run main function
main
