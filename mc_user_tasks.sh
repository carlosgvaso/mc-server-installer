#!/bin/bash

# Install mcrcon and minecraft server. This script assumes a minecraft user has
# been created already.
#
# Author: Jose Carlos Martinez Garcia-Vaso
#

# Check input
if [ "$#" -ne 6 ]; then
    printf "ERROR: install_server: wrong number of arguments provided\n"
    exit 1
fi

# Globals
SRC_DIR="$1"
MC_USER="$2"
MC_HOME="$3"
MC_PORT="$4"
RCON_PASSWD="$5"
RCON_PORT="$6"

# 
(
    # Go to the install directory
    cd ${MC_HOME}

    # Create the directory structure
    mkdir -p ${MC_HOME}/{backups,tools,server}

    # Install mcrcon
    git clone https://github.com/Tiiffi/mcrcon.git ${MC_HOME}/tools/mcrcon

    (
        cd ${MC_HOME}/tools/mcrcon

        # Compile mcrcon
        gcc -std=gnu11 -pedantic -Wall -Wextra -O2 -s -o mcrcon mcrcon.c
        ./mcrcon -v
    )

    # Install Minecraft server
    (
        cd ${MC_HOME}/server

        # Download the Minecraft server JAR
        wget https://launcher.mojang.com/v1/objects/a0d03225615ba897619220e256a266cb33a44b6b/server.jar -P ${MC_HOME}/server

        # Run server to create necessary files
        java -Xmx1024M -Xms1024M -jar ${MC_HOME}/server/server.jar nogui

        # Agree with EULA
        sed -i '/eula\=/ c eula=true' ${MC_HOME}/server/eula.txt

        # Enable rcon
        sed -i "/rcon.port=/ c rcon.port=${RCON_PORT}" ${MC_HOME}/server/server.properties
        sed -i "/rcon.password=/ c rcon.password=${RCON_PASSWD}" ${MC_HOME}/server/server.properties
        sed -i '/enable-rcon=/ c enable-rcon=true' ${MC_HOME}/server/server.properties

        # Set Minecraft server port
        sed -i "/server-port=/ c server-port=${MC_PORT}" ${MC_HOME}/server/server.properties
    )
    
    # Set up backup script
    (
        cd ${MC_HOME}/tools

        cp ${SRC_DIR}/backup.sh ${MC_HOME}/tools/
        chmod +x ${MC_HOME}/tools/backup.sh

        # Set backup script configs
        sed -i "/\/opt\/minecraft\/tools\/mcrcon\/mcrcon -H 127.0.0.1 -P rcon-port -p strong-password \"\$1\"/ c \ \ ${MC_HOME//\//\\\/}\/tools\/mcrcon\/mcrcon -H 127.0.0.1 -P ${RCON_PORT} -p ${RCON_PASSWD} \"\$1\"" ${MC_HOME}/tools/backup.sh
        sed -i "/tar -cvpzf \/opt\/minecraft\/backups\/server-$(date +%F-%H-%M).tar.gz \/opt\/minecraft\/server/ c tar -cvpzf ${MC_HOME//\//\\\/}\/backups\/server-$(date +%F-%H-%M).tar.gz ${MC_HOME//\//\\\/}\/server" ${MC_HOME}/tools/backup.sh
        sed -i "/find \/opt\/minecraft\/backups\/ -type f -mtime \+7 -name \'\*.gz\' -delete/ c find ${MC_HOME//\//\\\/}\/backups\/ -type f -mtime +7 -name '*.gz' -delete" ${MC_HOME}/tools/backup.sh

        # Add crontab
        cp ${SRC_DIR}/mc_user_crontab.txt ${MC_HOME}/tools/

        sed -i "/0 23 \* \* \* \/opt\/minecraft\/tools\/backup.sh/ c 0 23 * * * ${MC_HOME//\//\\\/}\/tools\/backup.sh" ${MC_HOME}/tools/mc_user_crontab.txt

        crontab ${MC_HOME}/tools/mc_user_crontab.txt
    )
)