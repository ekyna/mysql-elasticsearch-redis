#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" || exit

# Check env file
if [[ ! -f ./.env ]]
then
    printf "\e[31mEnv file not found\e[0m\n"
    exit 1;
fi

# Load and check config
source ./.env
source ./util.sh
ClearLogs

if [[ $(uname -s) = MINGW* ]]; then export MSYS_NO_PATHCONV=1; fi

# ----------------------------- INTERNAL -----------------------------

DoCreateNetworkAndVolumes() {
    NetworkCreate "${NETWORK_NAME}"
    VolumeCreate "${COMPOSE_PROJECT_NAME}-mysql"
    VolumeCreate "${COMPOSE_PROJECT_NAME}-elasticsearch"
#    VolumeCreate "${COMPOSE_PROJECT_NAME}-redis"
}

DoRemoveNetworkAndVolumes() {
    #NetworkRemove "${NETWORK_NAME}-network"
    VolumeRemove "${COMPOSE_PROJECT_NAME}-mysql"
    VolumeRemove "${COMPOSE_PROJECT_NAME}-elasticsearch"
#    VolumeRemove "${COMPOSE_PROJECT_NAME}-redis"
}

# ----------------------------- EXEC -----------------------------

case $1 in
    # -------------- UP --------------
    up)
        Title "Starting stack"
        Confirm

        DoCreateNetworkAndVolumes

        ComposeUp
    ;;
    # ------------- DOWN -------------
    down)
        Title "Stopping stack"
        Confirm

        ComposeDown
    ;;
    # ------------- RESET ------------
    reset)
        Title "Resetting stack"
        Warning "All data will be lost !"
        Confirm
        Warning "Are you really sure ?"
        Confirm

        ComposeDown
        DoRemoveNetworkAndVolumes

        sleep 5

        DoCreateNetworkAndVolumes
        ComposeUp
    ;;
    # ------------- CLEAR ------------
    clear)
        Title "Clearing stack"
        Warning "All data will be lost !"
        Confirm
        Warning "Are you really sure ?"
        Confirm

        ComposeDown
        DoRemoveNetworkAndVolumes
    ;;
    # -------------- TOOLS --------------
    tools)
        if [[ ! $2 =~ ^up|down$ ]]
        then
            printf "\e[31mExpected 'up' or 'down'\e[0m\n"
            exit 1
        fi

        if [[ $2 == 'up' ]]
        then
            ToolsUp
        else
            ToolsDown
        fi
    ;;
    # ------------- HELP -------------
    *)
        Help "Usage: ./manage.sh [action] [options]

  \e[0mup\e[2m              Create network and volumes and start containers.
  \e[0mdown\e[2m            Stop containers.
  \e[0mreset\e[2m           Recreate volumes and restart containers.
  \e[0mclear\e[2m           Stop containers and destroy the network and volumes.
  \e[0mtools\e[2m up|down   Start or stop tools containers."
    ;;
esac
