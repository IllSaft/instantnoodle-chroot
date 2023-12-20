#!/bin/bash
# Determine the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# ------------------------
# CONFIGURABLE SETTINGS 
# ------------------------

source "$SCRIPT_DIR/network_config.cfg"

# This script manages network configurations and initiates a telnet session.
# It checks for the existence of a specific device and configures network settings accordingly.

# ANSI color codes for enhanced readability
declare -A COLORS=(
    [INFO]='\033[1;34m'    # Blue for informational messages
    [SUCCESS]='\033[1;32m' # Green for success messages
    [WARNING]='\033[1;33m' # Yellow for warnings
    [ERROR]='\033[1;31m'   # Red for errors
    [RESET]='\033[0m'      # Reset to default color
)

# ------------------------
# UTILITY FUNCTIONS
# ------------------------

# Function to print messages in specified color
print_message() {
    local messageType=$1
    local message=$2
    echo -e "${COLORS[$messageType]}$message${COLORS[RESET]}"
}

# Function to check system requirements
check_system_requirements() {
    print_message INFO "Checking system requirements..."
    
    # Check for Bash version 4 or later
    if ((BASH_VERSINFO[0] < 4)); then
        print_message ERROR "Bash version 4 or later required."
        exit 1
    fi

    # Check for passwordless sudo access
    if ! sudo -n true 2>/dev/null; then
        print_message ERROR "Passwordless sudo required."
        exit 1
    fi

    print_message SUCCESS "System requirements met."
}

# Function to check if a network device exists
does_device_exist() {
    local deviceName=$1
    ip link show | grep -q "$deviceName"
}

# Function to check if a route is already set
is_route_set() {
    ip route show | grep -q "$TARGET_IP.*dev $DEVICE_NAME"
}

# Function to check network reachability
check_network_reachability() {
    print_message INFO "Checking network reachability to $TARGET_IP..."
    
    if ! ping -c 1 -W 1 "$TARGET_IP" &> /dev/null; then
        print_message ERROR "Target $TARGET_IP is not reachable. Check network configuration."
        exit 1
    fi

    print_message SUCCESS "Target $TARGET_IP is reachable."
}

# Function to configure network and initiate telnet
configure_network_and_telnet() {
    local deviceName=$1
    local configureRoute=$2

    print_message INFO "Configuring network settings for $deviceName..."
    
    # Configure network if required
    if [[ "$configureRoute" == true ]]; then
        sudo ip link set dev "$deviceName" up
        sudo ip address add 192.168.2.20 dev "$deviceName"
        sudo ip route add "$TARGET_IP" dev "$deviceName"
    fi

    # Check reachability and initiate telnet
    check_network_reachability
    initiate_telnet "$TARGET_IP"
}

# Function to initiate telnet session
initiate_telnet() {
    local targetIP=$1
    print_message INFO "Initiating telnet session to $targetIP..."
    
    telnet "$targetIP"
    local telnetStatus=$?

    if [ $telnetStatus -ne 0 ]; then
        print_message ERROR "Telnet session to $targetIP failed."
        return $telnetStatus
    else
        print_message SUCCESS "Telnet session to $targetIP closed successfully."
    fi
}

# Function to wait for a network device to appear
wait_for_device() {
    local devicePattern=$1
    local timeout=$2
    local count=0

    print_message WARNING "Waiting for device matching $devicePattern to appear..."
    while [ $count -lt $timeout ]; do
        local foundDevice=$(ip link show | grep -oP "$devicePattern")
        if [ ! -z "$foundDevice" ]; then
            print_message SUCCESS "Device $foundDevice detected."
            return 0
        fi
        sleep 1
        ((count++))
    done

    print_message ERROR "Device matching $devicePattern not found after $timeout seconds."
    return 1
}

# ------------------------
# MAIN LOGIC
# ------------------------

main() {
    check_system_requirements

    if does_device_exist "$DEVICE_NAME"; then
        print_message SUCCESS "$DEVICE_NAME already exists. Checking route..."

        if is_route_set; then
            print_message SUCCESS "Route to $TARGET_IP is already set on $DEVICE_NAME."
            configure_network_and_telnet "$DEVICE_NAME" false
        else
            print_message WARNING "Setting up route and IP for $DEVICE_NAME."
            configure_network_and_telnet "$DEVICE_NAME" true
        fi
    else
        # Wait for device matching 'enx' pattern
        wait_for_device 'enx[a-f0-9]+' 5
        if [ $? -eq 0 ]; then
            local newDeviceName=$(ip link show | grep -oP 'enx[a-f0-9]+')
            print_message INFO "Found device with 'enx' prefix: $newDeviceName. Setting up as $DEVICE_NAME."

            sudo ip link set down dev "$newDeviceName"
            sudo ip link set dev "$newDeviceName" name "$DEVICE_NAME"

            if does_device_exist "$DEVICE_NAME"; then
                print_message SUCCESS "Device renamed to $DEVICE_NAME successfully."
                configure_network_and_telnet "$DEVICE_NAME" true
            else
                print_message ERROR "Failed to rename device $newDeviceName to $DEVICE_NAME."
                exit 1
            fi
        else
            print_message ERROR "Device with 'enx' prefix not found."
            exit 1
        fi
    fi
}

# Execute main function
main
