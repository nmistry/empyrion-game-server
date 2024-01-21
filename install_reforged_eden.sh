#!/bin/bash

STEAM_LOGIN=$1
if [[ $STEAM_LOGIN == "" ]]; then
    echo "Please specify steam login"
    exit 1
fi

EDEN_TEMPORARY_DIR="/tmp"
EDEN_DOWNLOAD_DIR="$EDEN_TEMPORARY_DIR/steamapps/workshop/content/383120/2550354956"
EDEN_DESTINATION_DIR="/runtime/egs/Content/Scenarios/Reforged Eden"
if [[ ! -d EDEN_DESTINATION_DIR ]]; then
    mkdir -p $EDEN_DESTINATION_DIR
fi

steamcmd +force_install_dir "$EDEN_TEMPORARY_DIR" +login "$STEAM_LOGIN" +workshop_download_item 383120 2550354956 +quit

cp -Lr "$EDEN_DOWNLOAD_DIR" "$EDEN_DESTINATION_DIR"
rm -Rf "$EDEN_DOWNLOAD_DIR" 
