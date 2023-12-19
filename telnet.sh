#!/bin/bash

# Check if Bash version supports associative arrays
if ((BASH_VERSINFO[0] < 4)); then
    echo "This script requires Bash version 4 or later."
    exit 1
fi

# Define ANSI color codes using associative array
declare -A colors
colors=(
    [BLACK]='\033[0;30m' [RED]='\033[0;31m' [GREEN]='\033[0;32m' [YELLOW]='\033[0;33m'
    [BLUE]='\033[0;34m' [MAGENTA]='\033[0;35m' [CYAN]='\033[0;36m' [WHITE]='\033[0;37m'
    [BOLD_BLACK]='\033[1;30m' [BOLD_RED]='\033[1;31m' [BOLD_GREEN]='\033[1;32m'
    [BOLD_YELLOW]='\033[1;33m' [BOLD_BLUE]='\033[1;34m' [BOLD_MAGENTA]='\033[1;35m'
    [BOLD_CYAN]='\033[1;36m' [BOLD_WHITE]='\033[1;37m' [BOLD]='\033[1m' [RESET]='\033[0m'
)

# Function to display messages in different colors and styles
echo_colored() {
    local color=${colors[$1]} 
    shift
    echo -e "${color}$@${colors[RESET]}"
}

# Function to start a colored telnet session
start_colored_telnet_session() {
    local color_code=${colors[$1]}
    echo -e "${colors[CYAN]}Initiating telnet session to OnePlus 8.${colors[RESET]}"
    echo -e "${color_code}"
    telnet 192.168.2.15
    echo -e "${colors[RESET]}"
}


# Function to check if OnePlus-8 device exists
check_device_exists() {
    ip link show | grep -q 'OnePlus-8'
    return $?
}

# Function to check if the route for 192.168.2.15 is already set on OnePlus-8
route_already_set() {
    ip route show | grep -q '192.168.2.15.*dev OnePlus-8'
    return $?
}

# Display the output of 'ip route show' with a touch of style
echo_colored BOLD_MAGENTA "Output:"
echo_colored BOLD_BLUE "$(ip route show)"

# Main logic with vivid output
if check_device_exists; then
    echo_colored BOLD_GREEN "OnePlus 8 already exists. Setting IP and initiating telnet session..."

    if route_already_set; then
        echo_colored BOLD_GREEN "Route to 192.168.2.15 is already set on OnePlus 8..."
    else
        echo_colored BOLD_YELLOW "Setting up route and IP for OnePlus 8."
        sudo sh -c 'ip link set dev OnePlus-8 up && ip address add 192.168.2.20 dev OnePlus-8 && ip route add 192.168.2.15 dev OnePlus-8'
    fi
    start_colored_telnet_session BOLD_YELLOW
else
    device_name=$(ip route show | grep 'proto kernel scope' | grep -o 'enx[a-f0-9]\+')

    if [ -z "$device_name" ]; then
        echo_colored BOLD_RED "Device starting with 'enx' and containing 'proto kernel scope' not found."
        exit 1
    fi

    echo_colored BOLD_YELLOW "Setting up device $device_name as OnePlus 8."
    sudo sh -c "ip link set down dev $device_name && ip link set dev $device_name name OnePlus-8 && ip link set up dev OnePlus-8"
    
    echo_colored BOLD_YELLOW "Setting up IP and initiating telnet session for OnePlus 8."
    sudo sh -c 'ip link set dev OnePlus-8 up && ip address add 192.168.2.20 dev OnePlus-8 && ip route add 192.168.2.15 dev OnePlus-8'
    start_colored_telnet_session BOLD_YELLOW
fi
