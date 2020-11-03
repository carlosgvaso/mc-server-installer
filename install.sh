#!/bin/bash

# Installs the Minecraft server as a SystemD service with all required
# dependencies and mcrcon to communicate with the server in Ubuntu Linux.
#
# Author: Jose Carlos Martinez Garcia-Vaso <carlosgvaso@gmail.com>
#
# Based on the following guide:
# https://linuxize.com/post/how-to-make-minecraft-server-on-ubuntu-20-04/
#

# Globals
SRC_DIR="$(realpath $(dirname "$0"))"
MC_USER='minecraft'
MC_HOME='/opt/minecraft'
MC_PORT=25565
RCON_PASSWD='set-password-here'
RCON_PORT=25575

# Install dependencies
sudo apt update
sudo apt install git build-essential openjdk-11-jre-headless

# Create Minecraft user
sudo useradd -r -m -U -d ${MC_HOME} -s /bin/bash ${MC_USER}

# Install server
sudo su -c "bash mc_user_tasks.sh ${SRC_DIR} ${MC_USER} ${MC_HOME} ${MC_PORT} \
    ${RCON_PASSWD} ${RCON_PORT}" -m ${MC_USER}

# Install service
sudo cp minecraft.service /etc/systemd/system/minecraft.service

sudo sed -i "/WorkingDirectory=\/opt\/minecraft\/server/ c WorkingDirectory=${MC_HOME//\//\\\/}\/server" /etc/systemd/system/minecraft.service
sudo sed -i "/ExecStop=\/opt\/minecraft\/tools\/mcrcon\/mcrcon -H 127.0.0.1 -P rcon-port -p strong-password stop/ c ExecStop=${MC_HOME//\//\\\/}\/tools\/mcrcon\/mcrcon -H 127.0.0.1 -P ${RCON_PORT} -p ${RCON_PASSWD} stop" /etc/systemd/system/minecraft.service

sudo systemctl daemon-reload
sudo systemctl start minecraft
sudo systemctl enable minecraft
sudo systemctl status minecraft

# Configure firewall
sudo ufw allow ${MC_PORT}/tcp
