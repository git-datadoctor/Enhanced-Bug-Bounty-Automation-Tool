#!/bin/bash

# Main run script for Bug Bounty Automation Tool
# Provides a unified interface to all toolkit components

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if script is running with root privileges
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}Some features may require root privileges${NC}"
    fi
}

# Function to check if a script exists and is executable
check_script() {
    local script=$1
    if [ ! -x "$script" ]; then
        echo -e "${RED}Error: $script not found or not executable${NC}"
        return 1
    fi
    return 0
}

# Function to display main menu
show_menu() {
    clear
    echo -e "${BLUE}Bug Bounty Automation Toolkit${NC}"
    echo "============================"
    echo
    echo "1. Manage Targets"
    echo "2. Run Single Target Scan"
    echo "3. Run Batch Scan"
    echo "4. Generate Reports"
    echo "5. Maintenance"
    echo "6. Setup & Configuration"
    echo "7. Exit"
    echo
    echo -en "Select an option: "
}

# Function to show maintenance menu
show_maintenance_menu() {
    clear
    echo -e "${BLUE}Maintenance Options${NC}"
    echo "==================="
    echo
    echo "1. Check Tool Versions"
    echo "2. Update Tools"
    echo "3. Clean Old Results"
    echo "4. Back to Main Menu"
    echo
    echo -en "Select an option: "
}

# Function to show setup menu
show_setup_menu() {
    clear
    echo -e "${BLUE}Setup & Configuration${NC}"
    echo "====================="
    echo
    echo "1. Run Installation Script"
    echo "2. Test Setup"
    echo "3. Configure Settings"
    echo "4. Back to Main Menu"
    echo
    echo -en "Select an option: "
}

# Function to handle maintenance options
handle_maintenance() {
    while true; do
        show_maintenance_menu
        read choice
        
        case $choice in
            1)
                if check_script "./check_tools.sh"; then
                    ./check_tools.sh --check-only
                fi
                ;;
            2)
                if check_script "./check_tools.sh"; then
                    ./check_tools.sh --force-update
                fi
                ;;
            3)
                if check_script "./cleanup.sh"; then
                    echo -en "${BLUE}Enter days to keep (default: 30):${NC} "
                    read days
                    if [ -z "$days" ]; then
                        ./cleanup.sh
                    else
                        ./cleanup.sh --days "$days"
                    fi
                fi
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo
        echo -en "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Function to handle setup options
handle_setup() {
    while true; do
        show_setup_menu
        read choice
        
        case $choice in
            1)
                if check_script "./install_dependencies.sh"; then
                    sudo ./install_dependencies.sh
                fi
                ;;
            2)
                if check_script "./test_setup.sh"; then
                    ./test_setup.sh
                fi
                ;;
            3)
                if check_script "./setup_config.sh"; then
                    ./setup_config.sh
                fi
                ;;
            4)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo
        echo -en "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Function to run single target scan
run_single_scan() {
    echo -en "${BLUE}Enter target domain:${NC} "
    read target
    
    if [ -z "$target" ]; then
        echo -e "${RED}No target specified${NC}"
        return
    fi
    
    if check_script "./bug_bounty.sh"; then
        ./bug_bounty.sh "$target"
    fi
}

# Function to run batch scan
run_batch_scan() {
    if ! check_script "./batch_scan.sh"; then
        return
    fi
    
    echo -e "${BLUE}Batch Scan Options${NC}"
    echo "1. Run with default settings"
    echo "2. Run with custom settings"
    echo "3. Cancel"
    echo
    echo -en "Select an option: "
    read choice
    
    case $choice in
        1)
            ./batch_scan.sh
            ;;
        2)
            echo -en "${BLUE}Enter number of parallel scans:${NC} "
            read parallel
            echo -en "${BLUE}Enter delay between scans (seconds):${NC} "
            read delay
            
            cmd="./batch_scan.sh"
            [ -n "$parallel" ] && cmd="$cmd --parallel $parallel"
            [ -n "$delay" ] && cmd="$cmd --delay $delay"
            
            eval "$cmd"
            ;;
        3)
            return
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
}

# Function to generate reports
generate_reports() {
    if ! check_script "./generate_report.sh"; then
        return
    fi
    
    echo -en "${BLUE}Enter target domain:${NC} "
    read target
    
    if [ -z "$target" ]; then
        echo -e "${RED}No target specified${NC}"
        return
    fi
    
    echo -e "${BLUE}Report Formats${NC}"
    echo "1. HTML"
    echo "2. JSON"
    echo "3. Markdown"
    echo "4. All Formats"
    echo
    echo -en "Select format(s): "
    read format_choice
    
    case $format_choice in
        1) format="html" ;;
        2) format="json" ;;
        3) format="md" ;;
        4) format="html,json,md" ;;
        *) echo -e "${RED}Invalid format choice${NC}"; return ;;
    esac
    
    ./generate_report.sh --target "$target" --format "$format"
}

# Main execution
main() {
    check_root
    
    while true; do
        show_menu
        read choice
        
        case $choice in
            1)
                if check_script "./target_input.sh"; then
                    ./target_input.sh
                fi
                ;;
            2)
                run_single_scan
                ;;
            3)
                run_batch_scan
                ;;
            4)
                generate_reports
                ;;
            5)
                handle_maintenance
                ;;
            6)
                handle_setup
                ;;
            7)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
        
        echo
        echo -en "${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Run main function
main
