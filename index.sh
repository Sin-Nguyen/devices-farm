#!/bin/sh
complete -W "appium port device" index.sh

arg1=$1
index=$(seq $#)
for i in $index; do
 array+=${@:$(($i + 1))}
 break
done
appium() {
 sh $(pwd)/script/appium.sh ${array[@]}
}

pool_port() {
 sh $(pwd)/script/pool_port.sh ${array[@]}
}

pool_device() {
 sh $(pwd)/script/pool_devices.sh ${array[@]}
}

help() {
 echo "Usage: $0 [options]"
 echo "Options:"
 echo "  appium, --appium        Run appium with specific port"
 echo "  port,   --pool-port     Get port of appium on LeapXpert device farm"
 echo "  device, --pool-device   Get device of appium on LeapXpert device farm"
}

while [[ "$#" -gt 0 ]]; do
 case $1 in
 appium | --appium) appium shift ;;
 port   | --pool-port) pool_port shift ;;
 device | --pool-device) pool_device shift ;;
 *) echo "Unknown parameter passed $1" ;;
 esac
 shift
 exit 1
done

# ################################################################################
# # Help                                                                         #
# ################################################################################
help