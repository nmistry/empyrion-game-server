#!/bin/bash

# Fail entire script on error
set -e
# Directory where to store all downloaded runtime files
RUNTIME_DIR="/runtime"

# Empyrion Galactic Dedicated Server home directory
# TODO: Check permission for the dir
EGS_HOME_DIR="$RUNTIME_DIR/egs"
if [[ ! -d $EGS_HOME_DIR ]]; then
    mkdir -p "$EGS_HOME_DIR"
fi

# Empyrion dedicated server config
EGS_DEDICATED_CONFIG_FILE="$EGS_HOME_DIR/dedicated.yaml"
# Backup of original dedicated server config which will be used as default values
# on each startup
EGS_DEDICATED_CONFIG_BACKUP_FILE="$EGS_DEDICATED_CONFIG_FILE.backup"

#Logs directory
LOGS_DIR="$RUNTIME_DIR/Logs"
if [[ ! -d $LOGS_DIR ]]; then
    mkdir -p "$LOGS_DIR"
fi

# Empyrion Galctic Dedicated Server binary to launch
EGS_BINARY="$EGS_HOME_DIR/DedicatedServer/EmpyrionDedicated.exe"

# Wine configuration
export WINEPREFIX="${RUNTIME_DIR}/pfx"
export WINEARCH="win64"
export WINEDEBUG=${WINEDEBUG:="-all"}

# Lock wine files to not install every time when container starts
LOCK_FILE_WINE="${RUNTIME_DIR}/wine.lock"

# ENV Parameters
# How log wait after signal to server to shutdown
ENV_GRACEFUL_TIMEOUT="${ENV_GRACEFUL_TIMEOUT:=20}"
# How to start application
ENV_CONSOLE_TYPE="${ENV_CONSOLE_TYPE:=-batchmode -nographics}"

rm -f /tmp/.X5-lock
rm -Rf /tmp/.wine*
echo "===> Starting fake display to install winetricks dependencies"    
export DISPLAY=":5.0"
Xvfb :5 -screen 0 1024x768x16 > /dev/null 2>&1 &    
export WINEDLLOVERRIDES="mscoree,mshtml=" 

# Configure wine prefix if needed
if [[ ! -f "$LOCK_FILE_WINE" ]]; then    
     echo "===> Creating wine prefix in $WINEPREFIX"
     env wineboot --init /nogui

     touch "$LOCK_FILE_WINE"
    
     echo "===> Updating game files in direcotry $EGS_HOME_DIR"
     steamcmd +@sSteamCmdForcePlatformType windows \
         +force_install_dir "$EGS_HOME_DIR" \
         +login anonymous \
         +app_update 530870 validate \
         +quit
fi

# Creating backup of server config if does not exists
if [[ ! -f $EGS_DEDICATED_CONFIG_BACKUP_FILE ]]; then
    mv "$EGS_DEDICATED_CONFIG_FILE" "$EGS_DEDICATED_CONFIG_BACKUP_FILE"
fi

# Processing env variable
CRL=$EGS_DEDICATED_CONFIG_BACKUP_FILE CWL=$EGS_DEDICATED_CONFIG_FILE env-helper 

function _LoggingRouting() {
    sleep 15
    until [ "$(ss -ntl | tail -n+3)" ]; do sleep 1; done
    sleep 10
    echo "Open logs"
    tail -F "$LOGS_DIR"/current.log "$LOGS_DIR"/wine.log "$LOGS_DIR"/*/*.log 2> /dev/null
}

_LoggingRouting &

CMD="wine $EGS_BINARY $ENV_CONSOLE_TYPE -logFile ${LOGS_DIR}/current.log &> ${LOGS_DIR}/wine.log"
echo "===> Staring dedicated server using command '$CMD'"
cd $EGS_HOME_DIR && wine "$EGS_BINARY" "$ENV_CONSOLE_TYPE" -logFile "$LOGS_DIR"/current.log &> "$LOGS_DIR"/wine.log
