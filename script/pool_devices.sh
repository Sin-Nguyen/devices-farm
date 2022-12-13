#!/bin/sh
address=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')

if ! [ -x "$(command -v jq)" ]; then
    brew install jq curl
fi
################################################################################
# Help                                                                         #
################################################################################
help() {
    echo "GET DEVICE LIST ON LEAPXPERT DEVICE FARM"
    echo ""
    echo "Usage: index.sh device -p port [options]"
    echo ""
    echo "Options:"
    echo "  -l, --list-devices  List devices with specific port"
    echo "  -h, --help          Show this help"
    echo "  -ready, --no-busy   Show devices ready to use"
    echo "  -d, --device-info   Show devices information with specific uuid"
    echo ""
    echo "Example usage:"
    echo "  index.sh device -p 4724 -l"
}
array="$@"
if [[ ${@: -1} == "-p" ]]; then
    help
    exit 1
elif [[ ${@: -1} == "-d" ]]; then
    echo "Error: Missing uuid of device to get device info"
    echo "Example usage:"
    echo "  $0 -p 4724 -d {uuid}"
    exit 1
fi
specific_port=$2 #for get_list_devices
device_uuid=$4 #for get_device_info

################################################################################
# get list devices                                                             #
################################################################################
get_list_devices() {
    list_device=$(curl -s --request GET "http://$address:$specific_port/device-farm/api/devices")
    if [ ! $? -eq 0 ]; then
        echo "Error: Can't get list devices. Please check port is running or not"
        exit 1
    fi
    echo $list_device | jq 'map({(.udid): .})| add'

}

################################################################################
# get device info                                                              #
################################################################################
get_device_info() {
    deviceReadyList=$(curl -s --request GET "http://$address:$specific_port/device-farm/api/devices" )
    if [ ! $? -eq 0 ]; then
        echo "Error: Can't get device info. Please check port is running or not"
        exit 1
    fi
    echo $deviceReadyList | jq 'map({(.udid): .})| add' | jq -r ".\"$device_uuid\""
}

################################################################################
# get list devices ready                                                       #
################################################################################
get_device_ready() {
    deviceList=$(curl -s --request GET "http://$address:$specific_port/device-farm/api/devices")
    if [ ! $? -eq 0 ]; then
        echo "Error: Can't get list devices ready. Please check port is running or not"
        exit 1
    fi
    echo $deviceList | jq -r '.[] | select(.busy == false)'
}

while [[ "$#" -gt 0 ]]; do
    case $3 in
    -ready | --no-busy) get_device_ready shift ;;
    -d | --device-info) get_device_info shift ;;
    -l | --list-device) get_list_devices shift ;;
    esac
    shift
    exit 1
done

################################################################################
# Main program                                                                 #
################################################################################
help
