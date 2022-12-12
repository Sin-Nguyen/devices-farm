#!/bin/sh
PORT=""
APPIUM_PATH=$(which appium)
PATH_APPIUM_CONFIG="$(pwd)/node/config.appiumrc.json"

# install jq
if ! [ -x "$(command -v jq)" ]; then
  brew install jq
fi

################################################################################
# assign PORT value in variable when trigger                                   #
# with -k | --kill-PORT or --start | --start-appium                            #
################################################################################
case "$1" in
"-kill" | "--kill-port")
  PORT=$2
  ;;
"-start" | "--start-appium")
  PORT="$3"
  ;;
esac

################################################################################
# Kill specific port                                                            #
################################################################################
killing_port() {
  if [ -n "$PORT" ] && [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
    PORT=$PORT
  else
    echo "ERROR: PORT not found. Please check again"
    exit 1
  fi
  if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
    echo "Finding PORT $PORT"
    echo ""
    echo "Killing PORT $PORT"
    kill -9 $(lsof -t -i:$PORT)
    echo ""
    echo "PORT $PORT is killed"
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null; then
      echo "PORT $PORT ready to use"
      exit 1
    fi
  else
    echo "Error: PORT $PORT is not running. Please check again"
    exit 1
  fi
}

################################################################################
# run appium with specific PORT and device type                                 #
################################################################################
start() {
  if [ -n "$PORT" ] && [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
    PORT=$PORT
  else
    echo "ERROR: Missing PORT. Please check again"
    echo ""
    echo "ex: $(pwd)/index.sh appium -start -p 4724"
    exit 1
  fi
  echo "Starting appium on port $PORT"
  # show appium config
  echo "Appium config is: $(jq . $PATH_APPIUM_CONFIG)"
  echo ""
  echo "Please wait a bit for appium to start..."
  address=$(ipconfig getifaddr en0)
  # run appium with specific PORT
  cmd="$APPIUM_PATH --address $address --port $PORT --config $PATH_APPIUM_CONFIG"
  osascript <<EOF
      tell application "Terminal" to do script "${cmd}"
EOF
}

################################################################################
# Help                                                                         #
################################################################################
help() {
  echo "TRIGGER TO START APPIUM WITH SPECIFIC PORT AND DEVICE TYPE"
  echo ""
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -kill, --kill-port           Kill specific PORT"
  echo "  -start,--start-appium        Start appium with specific PORT"
  echo "  -h,    --help                Show this help"
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
  -kill | --kill-port) killing_port shift ;;
  -start | --start-appium) start shift ;;
  -help | --help) help shift ;;
  *) echo "Unknown parameter passed: $1. Prefer to use -h or --help for more detail" ;;
  esac
  shift
  exit 1
done

################################################################################
# Main program                                                                 #
################################################################################
help
