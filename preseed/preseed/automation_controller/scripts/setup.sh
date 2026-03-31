#!/usr/bin/env bash
# 
# /usr/bin/setup --> $HOME/setup.sh
# 
# Runs on first login of newly installed
# automation controller. Once first config is
# saved, "$SKIP_SETUP" is set to '1' and this
# script is skipped unless manually invoked.

# Location to save Kramer interface variables
export CONFIG_FILE="${CONFIG_FILE:-"$HOME/.kramer_config"}"

if [ -f "$CONFIG_FILE" ]; then 
    # shellcheck disable=SC1090
    . "$CONFIG_FILE"
fi

export SKIP_SETUP="${SKIP_SETUP:="0"}"

# Default Kramer interface variables
export KRAMER_IP="${KRAMER_IP:="192.168.1.100"}"
export KRAMER_PORT="${KRAMER_PORT:=8000}"
export KRAMER_INTERFACE="${KRAMER_INTERFACE:=""}"
export KRAMER_PAGE="${KRAMER_PAGE:=""}"
export KRAMER_IMMERSIVE="${KRAMER_IMMERSIVE:="true"}"
export SCREEN_TIMEOUT="${SCREEN_TIMEOUT:="15"}"

function save_config () {
    # Write variables to config file
    cat << EOF > "$CONFIG_FILE"
export SKIP_SETUP="1"
export KRAMER_IP="${KRAMER_IP}"
export KRAMER_PORT="${KRAMER_PORT}
export KRAMER_INTERFACE="${KRAMER_INTERFACE}"
export KRAMER_PAGE="${KRAMER_PAGE}"
export KRAMER_IMMERSIVE="${KRAMER_IMMERSIVE}"
export SCREEN_TIMEOUT="${SCREEN_TIMEOUT}"
EOF
}

function print_config() {
   cat << EOF
KRAMER_IP="${KRAMER_IP}"
KRAMER_INTERFACE="${KRAMER_INTERFACE}"
KRAMER_PAGE="${KRAMER_PAGE}"
KRAMER_IMMERSIVE="${KRAMER_IMMERSIVE}"
SCREEN_TIMEOUT="${SCREEN_TIMEOUT}"
EOF
}

function set_host_ip () {
    # Get available interfaces
    readarray -t INTERFACES < <(nmcli --colors no --get-value Name connection)
    INTERFACES_COUNT=$(( ${#INTERFACES[@]} - 1 ))
    SELECTED_INTERFACE_INDEX=-1

    # Re-prompt for index until input is valid (numeric and within range)
    while ! [[ "$SELECTED_INTERFACE_INDEX" =~ ^[0-9]+$ ]] \
        || [ "$SELECTED_INTERFACE_INDEX" -lt 0 ] \
        || [ "$SELECTED_INTERFACE_INDEX" -gt "$INTERFACES_COUNT" ]; 
    do
        clear
        echo 'Select interface'
        for i in "${!INTERFACES[@]}"; do 
            echo "    $i) ${INTERFACES[$i]}"
        done
        read -r -p "Select [0-$INTERFACES_COUNT]: " SELECTED_INTERFACE_INDEX
    done

    SELECTED_INTERFACE="${INTERFACES[$SELECTED_INTERFACE_INDEX]}"

    if [ -z "${SELECTED_INTERFACE}" ]; then 
        echo "No interface was selected"
        read -r -p "Press [Enter] to quit"
        return 1
    fi 

    CURRENT_IP=$(nmcli connection show "${SELECTED_INTERFACE}" | awk '$1=="ipv4.addresses:"{ print $2 }')

    NEW_IP=""

    # Re-prompt for IP until input is valid
    # WARNING: this regex allows invalid IPs (e.g. (000.000.000.000)).
    while ! [[ "$NEW_IP" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,2}$ ]]; 
    do
        echo "Selected Interface: ${SELECTED_INTERFACE}"
        echo "Current IP: ${CURRENT_IP}"
        echo "Enter new IP in CIDR notation (ex: 192.168.1.100/24)"
        read -r -p "New IP: " NEW_IP
    done

    nmcli con mod "${SELECTED_INTERFACE}" \
        ipv4.method manual \
        ipv4.addresses "${NEW_IP}" \
        ipv4.gateway "${KRAMER_IP}" \
        ipv4.dns "${KRAMER_IP}"

    nmcli con down "${SELECTED_INTERFACE}"
    nmcli con up "${SELECTED_INTERFACE}"
    read -r -p "Press [Enter] to continue"
}

function set_screen_timeout() {
    clear

    echo "Current settings:"
    echo
    # --- START COPILOT-GENERATED SCRIPT
    xset q | awk '/^DPMS/{ found=1; next }
    found {
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^Standby:/) print "Standby: " $(i+1);
            else if ($i ~ /^Suspend:/) print "Suspend: " $(i+1);
            else if ($i ~ /^Off:/) print "Off: " $(i+1);
        }
    }'
    # --- END COPILOT-GENERATED SCRIPT
    echo
    read -r -p "New Screen Blank Timeout (seconds) [$SCREEN_TIMEOUT]: " input_time
    SCREEN_TIMEOUT=${input_time:-$SCREEN_TIMEOUT}
    xset s "$SCREEN_TIMEOUT" "$SCREEN_TIMEOUT" 
    xset dmps "$SCREEN_TIMEOUT" "$SCREEN_TIMEOUT" "$SCREEN_TIMEOUT"
}

function set_options () {
    clear
    echo "Current config: "
    echo
    print_config
    echo

    read -r -p "Enter Kramer Brain IP (Leave blank for default) [$KRAMER_IP]: " input_ip
    KRAMER_IP=${input_ip:-$KRAMER_IP}

    read -r -p "Enter Kramer Brain Port (Leave blank for default) [$KRAMER_PORT]: " input_ip
    KRAMER_PORT=${input_PORT:-$KRAMER_PORT}
 
    read -r -p "Enter Interface Name (Leave blank for default) [$KRAMER_INTERFACE]: " input_int
    KRAMER_INTERFACE=${input_int:-$KRAMER_INTERFACE}
 
    read -r -p "Enter Start Page Name (Leave blank for default) [$KRAMER_PAGE]: " input_page
    KRAMER_PAGE=${input_page:-$KRAMER_PAGE}
 
    read -r -p "Use Immersive Mode (true/false) [$KRAMER_IMMERSIVE]: " input_imm
    KRAMER_IMMERSIVE=${input_imm:-$KRAMER_IMMERSIVE}
 
    echo "New config: "
    print_config
    echo

    unset choice
    while [ -z "$choice" ]; do 
        read -r -p "Save these settings to \"${CONFIG_FILE}\"? (y/n) " choice
    done

    case $choice in 
            "y") save_config; echo "Settings saved" ;;
            "")  echo "Must enter 'y' or 'n'" ;;
            "*") echo "Settings not saved" ;;
    esac 

    read -r -p "Press [Enter] to continue"
}

function install_dependencies () {
    # This requires sudo access
    sudo apt update && sudo apt install -y chromium pcmanfm zutty
}


function main () {
    while true; do 
        clear
        echo
        echo "1) Set static IP"
        echo "2) Set Kramer interface options"
        echo "3) Set Screen Timeout"
        echo "4) Re-install Dependencies"
        echo "5) Exit & Start App"
        echo "6) Exit"

        read -r -p "Select [1-5]: " choice
        case $choice in 

            # Set this computer's static IP
            1) set_host_ip ;;

            # Set variables for kramer options
            2) set_options ;;

            3) set_screen_timeout ;;

            4) install_dependencies ;;

            # Start chromium and exit
            5) 
                clear
                echo "Starting interface..."
                zutty -e start_interface &
                break
            ;;

            # Exit without starting chromium
            6) 
                clear 
                echo "Exiting" 
                break 
            ;;

            # All invalid or unimplemented options
            *) 
                echo "Not Implemented" 
                read -r -p "Press [Enter] to continue" 
            ;;
        esac
    done
}

main