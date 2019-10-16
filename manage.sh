#!/bin/bash

cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check env file
if [[ ! -f './.env' ]]
then
    printf "\e[31mEnv file not found\e[0m\n"
    exit 1;
fi

# Load and check config
source ./.env
source ./util.sh
ClearLogs

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

  \e[0mup\e[2m                      Create network and volumes and start containers.
  \e[0minit\e[2m                    Initialize the php service.
  \e[0mupdate\e[2m                  Pull images, rebuild and restart containers.
  \e[0mdown\e[2m                    Stop containers.
  \e[0mreset\e[2m                   Recreate volumes and restart containers.
  \e[0mclear\e[2m                   Stop containers and destroy the network and volumes.
  \e[0mpurge\e[2m                   Purges all caches.
  \e[0msf\e[2m command              Run the symfony <command> in the php container.
  \e[0mbackup\e[2m                  Backup database and files.
  \e[0mrestore\e[2m date            Restore the <date> backup database and files.
  \e[0mremote-restore\e[2m date     Restore database and files from remote backup.
  \e[0mtools\e[2m up|down           Start or stop tools containers."
    ;;
esac
