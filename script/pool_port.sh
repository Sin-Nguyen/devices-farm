#!/bin/sh
specific_port=$2
starting_port=4724
ending_port=4744
address=$(ifconfig | grep "inet " | grep -Fv 127.0.0.1 | awk '{print $2}')

################################################################################
# check ports are runned by appium or not                                                                         #
################################################################################
check_range_ports() {
    echo "Checking ports from $starting_port to $ending_port"
    for i in $(seq $starting_port $ending_port); do
        if ! lsof -Pi :$i -sTCP:LISTEN -t >/dev/null; then
            echo "$i ........... READY"
            port_to_use=$i
        elif lsof -Pi :$i -sTCP:LISTEN -t >/dev/null; then
            echo "$i ........... Busy"
        fi
    done
}

################################################################################
# check specific port with $2                                                                         #
################################################################################
check_specific_port() {
    echo "Checking port $specific_port"
    if ! lsof -Pi :$specific_port -sTCP:LISTEN -t >/dev/null; then
        echo "$specific_port ........... READY"
        port_to_use=$specific_port
    elif lsof -Pi :$specific_port -sTCP:LISTEN -t >/dev/null; then
        echo "$specific_port ........... Busy"
    fi
}

################################################################################
# Help                                                                         #
################################################################################
help() {
    echo "GET PORT OF APPIUM ON LEAPXPERT DEVICE FARM"
    echo ""
    echo "Usage: index.sh port [options]"
    echo "Options:"
    echo "  -l, --list-port  List status ports from 4724 to 4730"
    echo "  -p, --port       Check specific port"
    echo "  -h, --help       Show this help"
    echo ""
    echo "Example usage:"
    echo "  index.sh port -l"
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -l | --list-port)
        check_range_ports
        shift
        ;;
    -p | --port)
        check_specific_port
        shift
        ;;
    -h | --help)
        help
        shift
        ;;
    *) echo "Unknown parameter passed: $1" ;;
    esac
    shift
    exit 1
done

################################################################################
# Main program                                                                         #
################################################################################
help
