#!/bin/bash

# Interactive target input form for Bug Bounty Automation Tool
# Helps users add and manage target domains with proper validation

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TARGETS_FILE="targets.txt"
BACKUP=true

# Help message
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -f, --file FILE       Target file to edit (default: targets.txt)"
    echo "  --no-backup          Don't create backup of existing targets file"
    echo "  -h, --help           Show this help message"
    echo
    echo "Example:"
    echo "  $0 --file custom_targets.txt"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            TARGETS_FILE="$2"
            shift 2
            ;;
        --no-backup)
            BACKUP=false
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

# Function to validate domain format
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Function to validate scope format
validate_scope() {
    local scope=$1
    # Allow comma-separated list of domains/wildcards
    if [[ ! $scope =~ ^(\*\.[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}|[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,})(,(\*\.[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}|[a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}))*$ ]]; then
        return 1
    fi
    return 0
}

# Function to backup targets file
backup_targets() {
    if [ "$BACKUP" = true ] && [ -f "$TARGETS_FILE" ]; then
        local backup_file="${TARGETS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$TARGETS_FILE" "$backup_file"
        echo -e "${GREEN}Backup created: $backup_file${NC}"
    fi
}

# Function to add target
add_target() {
    echo -e "${BLUE}Adding New Target${NC}"
    echo "-------------------"
    
    # Get target domain
    while true; do
        echo -en "${BLUE}Enter target domain${NC}: "
        read domain
        if validate_domain "$domain"; then
            break
        else
            echo -e "${RED}Invalid domain format. Example: example.com${NC}"
        fi
    done
    
    # Get scope
    while true; do
        echo -en "${BLUE}Enter scope (comma-separated, wildcards allowed)${NC} [*.${domain}]: "
        read scope
        scope=${scope:-"*.${domain}"}
        if validate_scope "$scope"; then
            break
        else
            echo -e "${RED}Invalid scope format. Example: *.example.com,api.example.com${NC}"
        fi
    done
    
    # Get program name
    echo -en "${BLUE}Enter program name${NC} [Optional]: "
    read program
    
    # Get additional notes
    echo -en "${BLUE}Enter notes${NC} [Optional]: "
    read notes
    
    # Add to targets file
    {
        echo
        echo "# Target added on $(date)"
        echo "# Program: ${program:-Unknown}"
        [ -n "$notes" ] && echo "# Notes: $notes"
        echo "$domain $scope ${program:-\"Unknown Program\"}"
    } >> "$TARGETS_FILE"
    
    echo -e "${GREEN}Target added successfully!${NC}"
}

# Function to list targets
list_targets() {
    if [ ! -f "$TARGETS_FILE" ]; then
        echo -e "${RED}No targets file found${NC}"
        return
    fi
    
    echo -e "${BLUE}Current Targets${NC}"
    echo "---------------"
    
    local count=0
    while IFS= read -r line; do
        if [[ $line =~ ^#.*$ ]]; then
            echo -e "${YELLOW}$line${NC}"
        elif [[ -n $line ]]; then
            ((count++))
            echo -e "${GREEN}$count.${NC} $line"
        fi
    done < "$TARGETS_FILE"
    
    if [ $count -eq 0 ]; then
        echo "No targets found"
    else
        echo -e "\nTotal targets: $count"
    fi
}

# Function to remove target
remove_target() {
    if [ ! -f "$TARGETS_FILE" ]; then
        echo -e "${RED}No targets file found${NC}"
        return
    fi
    
    list_targets
    
    echo -en "\n${BLUE}Enter target number to remove${NC}: "
    read target_num
    
    if ! [[ "$target_num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input${NC}"
        return
    fi
    
    local count=0
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
        if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
            echo "$line" >> "$temp_file"
        else
            ((count++))
            if [ $count -ne $target_num ]; then
                echo "$line" >> "$temp_file"
            else
                target_to_remove=$line
            fi
        fi
    done < "$TARGETS_FILE"
    
    if [ -n "$target_to_remove" ]; then
        mv "$temp_file" "$TARGETS_FILE"
        echo -e "${GREEN}Removed target: $target_to_remove${NC}"
    else
        rm "$temp_file"
        echo -e "${RED}Target number not found${NC}"
    fi
}

# Function to edit target
edit_target() {
    if [ ! -f "$TARGETS_FILE" ]; then
        echo -e "${RED}No targets file found${NC}"
        return
    fi
    
    list_targets
    
    echo -en "\n${BLUE}Enter target number to edit${NC}: "
    read target_num
    
    if ! [[ "$target_num" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid input${NC}"
        return
    fi
    
    local count=0
    local temp_file=$(mktemp)
    local found=false
    
    while IFS= read -r line; do
        if [[ $line =~ ^#.*$ ]] || [[ -z $line ]]; then
            echo "$line" >> "$temp_file"
        else
            ((count++))
            if [ $count -eq $target_num ]; then
                found=true
                read domain scope program <<< "$line"
                
                echo -e "\n${BLUE}Editing target: $line${NC}"
                
                # Edit domain
                while true; do
                    echo -en "${BLUE}Enter new domain${NC} [$domain]: "
                    read new_domain
                    new_domain=${new_domain:-$domain}
                    if validate_domain "$new_domain"; then
                        break
                    else
                        echo -e "${RED}Invalid domain format${NC}"
                    fi
                done
                
                # Edit scope
                while true; do
                    echo -en "${BLUE}Enter new scope${NC} [$scope]: "
                    read new_scope
                    new_scope=${new_scope:-$scope}
                    if validate_scope "$new_scope"; then
                        break
                    else
                        echo -e "${RED}Invalid scope format${NC}"
                    fi
                done
                
                # Edit program name
                echo -en "${BLUE}Enter new program name${NC} [$program]: "
                read new_program
                new_program=${new_program:-$program}
                
                echo "$new_domain $new_scope $new_program" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        fi
    done < "$TARGETS_FILE"
    
    if [ "$found" = true ]; then
        mv "$temp_file" "$TARGETS_FILE"
        echo -e "${GREEN}Target updated successfully${NC}"
    else
        rm "$temp_file"
        echo -e "${RED}Target number not found${NC}"
    fi
}

# Main menu
main_menu() {
    while true; do
        echo -e "\n${BLUE}Bug Bounty Target Manager${NC}"
        echo "------------------------"
        echo "1. Add new target"
        echo "2. List targets"
        echo "3. Edit target"
        echo "4. Remove target"
        echo "5. Exit"
        echo
        echo -en "Select an option: "
        read choice
        
        case $choice in
            1)
                add_target
                ;;
            2)
                list_targets
                ;;
            3)
                edit_target
                ;;
            4)
                remove_target
                ;;
            5)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done
}

# Create targets file if it doesn't exist
if [ ! -f "$TARGETS_FILE" ]; then
    echo "# Bug Bounty Target List" > "$TARGETS_FILE"
    echo "# Format: domain scope program_name" >> "$TARGETS_FILE"
    echo "# Example: example.com *.example.com \"Example Program\"" >> "$TARGETS_FILE"
    echo -e "${GREEN}Created new targets file: $TARGETS_FILE${NC}"
else
    backup_targets
fi

# Run main menu
main_menu
