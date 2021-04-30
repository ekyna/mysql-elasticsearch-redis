#!/bin/bash

if [[ -z ${COMPOSE_PROJECT_NAME+x} ]]; then printf "\e[31mThe 'COMPOSE_PROJECT_NAME' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${NETWORK_NAME+x} ]]; then printf "\e[31mThe 'NETWORK_NAME' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${MYSQL_VERSION+x} ]]; then printf "\e[31mThe 'MYSQL_VERSION' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${MYSQL_ROOT_PASSWORD+x} ]]; then printf "\e[31mThe 'MYSQL_ROOT_PASSWORD' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${MYSQL_PORT+x} ]]; then printf "\e[31mThe 'MYSQL_PORT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${PHPMYADMIN_PORT+x} ]]; then printf "\e[31mThe 'PHPMYADMIN_PORT' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${ELASTICSEARCH_VERSION+x} ]]; then printf "\e[31mThe 'ELASTICSEARCH_VERSION' variable is not defined.\e[0m\n"; exit 1; fi
if [[ -z ${CHROME_TO_PDF_TOKEN+x} ]]; then printf "\e[31mThe 'CHROME_TO_PDF_TOKEN' variable is not defined.\e[0m\n"; exit 1; fi

LOG_PATH="./logs/docker.log"

# ----------------------------- HEADER -----------------------------

Title() {
    printf "\n\e[1;46m ----- %s ----- \e[0m\n" "$1"
}

Success() {
    printf "\e[32m%s\e[0m\n" "$1"
}

Error() {
    printf "\e[31m%s\e[0m\n" "$1"
}

Warning() {
    printf "\e[31;43m%s\e[0m\n" "$1"
}

Comment() {
    printf "\e[36m%s\e[0m\n" "$1"
}

Help() {
    printf "\e[2m%s\e[0m\n" "$1"
}

Ln() {
    printf "\n"
}

DoneOrError() {
    if [[ $1 -eq 0 ]]
    then
        Success 'done'
    else
        Error 'error'
        exit 1
    fi
}

Confirm () {
    Ln

    choice=""
    while [[ "$choice" != "n" ]] && [[ "$choice" != "y" ]]
    do
        printf "Do you want to continue ? (N/Y)"
        read choice
        choice=$(echo "${choice}" | tr '[:upper:]' '[:lower:]')
    done

    if [[ "$choice" = "n" ]]; then
        Warning "Abort by user"
        exit 0
    fi

    Ln
}

ClearLogs() {
    echo "" > ${LOG_PATH}
}

# ----------------------------- NETWORK -----------------------------

NetworkExists() {
    if docker network ls --format '{{.Name}}' | grep -q "$1\$"
    then
        return 0
    fi
    return 1
}

NetworkCreate() {
    printf "Creating network \e[1;33m%s\e[0m ... " "$1"
    if ! NetworkExists "$1"
    then
        docker network create "$1" >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "created"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "exists"
    fi
}

NetworkRemove() {
    printf "Removing network \e[1;33m%s\e[0m ... " "$1"
    if NetworkExists "$1"
    then
        docker network rm "$1" >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "removed"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "unknown"
    fi
}

# ----------------------------- VOLUME -----------------------------

VolumeExists() {
    if docker volume ls --format '{{.Name}}' | grep -q "$1\$"
    then
        return 0
    fi
    return 1
}

VolumeCreate() {
    printf "Creating volume \e[1;33m%s\e[0m ... " "$1"
    if ! VolumeExists $1
    then
        docker volume create --name "$1" >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "created"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "exists"
    fi
}

VolumeRemove() {
    printf "Removing volume \e[1;33m%s\e[0m ... " "$1"
    if VolumeExists "$1"
    then
        docker volume rm "$1" >> ${LOG_PATH} 2>&1
        if [[ $? -eq 0 ]]
        then
            Success "removed"
        else
            Error "error"
            exit 1
        fi
    else
        Comment "unknown"
    fi
}

# ----------------------------- COMPOSE -----------------------------

IsUpAndRunning() {
    if docker ps --format '{{.Names}}' | grep -q "${COMPOSE_PROJECT_NAME}_$1\$"
    then
        return 0
    fi
    return 1
}

ComposeUp() {
    printf "Composing \e[1;33mUp\e[0m ... "
    docker-compose -f compose.yml up -d >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

ComposeDown() {
    printf "Composing \e[1;33mDown\e[0m ... "
    docker-compose -f compose.yml down -v --remove-orphans >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

ComposeCreate() {
    printf "Creating services ... "
    docker-compose -f compose.yml create >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

# ----------------------------- TOOLS -----------------------------

# ToolsUp
ToolsUp() {
    if ! IsUpAndRunning mysql
    then
        printf "\e[31mMySql is not running.\e[0m\n"
        exit 1
    fi

    printf "Composing up \e[1;33mtools\e[0m ... "

    docker-compose -f tools.yml up -d >> ${LOG_PATH} 2>&1
    DoneOrError $?
}

# ToolsDown
ToolsDown() {
    if ! IsUpAndRunning phpmyadmin
    then
        printf "\e[31mTools are not up.\e[0m\n"
        exit 1
    fi

    printf "Composing down \e[1;33mtools\e[0m ... "

    docker-compose -f tools.yml down -v >> ${LOG_PATH} 2>&1
    DoneOrError $?
}
