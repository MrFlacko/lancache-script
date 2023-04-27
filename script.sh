#!/bin/bash

# Some Global Variables
osVersion="$(lsb_release -a 2> /dev/null | grep Desc | sed -e 's/.*://' -e 's/^[ \t]*//')"
lancacheDIR="/var/lib"
lancacheDockerLink="https://github.com/lancachenet/docker-compose"
lancacheDirectoryName="lancache"

# Some colours that are used throughout the script
LIGHT_RED='\033[1;31m'
RED='\033[0;31m'
LIGHT_DARK_GRAY='\033[0;96m'
BLUE='\033[1;34m'
DARK_GRAY='\033[0;37m'
LIGHT_GREEN='\033[1;32m'
NoColor='\033[0m'

# Initial Checks to make sure the script can run
[[ $EUID -ne 0 ]] && echo -e ""$RED"Error: Please run this script with root privileges (sudo)"$NoColor"" && exit 1

# Updating the system packages to make sure you have the correct versions of everything
runSystemUpdates() {
    clear && echo -e "\n\t${DARK_GRAY}Updating System Repositories...${NoColor}" && sleep 3
    apt update
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Updating System...${NoColor}" && sleep 3
    apt upgrade -y
}

# Installing latest version of Docker and DockerCompose
installDocker() {
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Installing Key Dependencies...${NoColor}" && sleep 3
    apt install apt-transport-https ca-certificates curl software-properties-common git -y
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Adding Docker Updated Repositories...${NoColor}" && sleep 3
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    apt-cache policy docker-ce
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Installing Docker and Docker-Compose...${NoColor}" && sleep 3
    apt install docker-ce docker-compose -y
}

# The first setup of Lancache, where the user can input required infomation
lancacheSetup() {
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Setting up lancache...${NoColor}" && sleep 3
    cd $lancacheDIR
    git clone $lancacheDockerLink $lancacheDirectoryName
    cd $lancacheDirectoryName
    sleep 3 && clear && echo -e "\n\t${DARK_GRAY}Listing IP Addresses...${NoColor}" && sleep 3
    ip a | grep inet
    echo
    read -p "Press Enter to customize Cache settings, Once settings are saved script will continue"
    nano .env
}

# Setting up lancache to start on boot, and restart every 24 hours
lancacheAutoRestart() {
    cd $lancacheDIR/$lancacheDirectoryName
    cp docker-compose.yml docker-compose-old.yml
    cat docker-compose-old.yml | 
        sed -e '/HTTPS/,/tcp/d' -e 's/#\ \ \ \ restart\: unless-stopped/\ \ \ \ restart\: always/' | 
        cat -s > docker-compose.yml
    rm docker-compose-old.yml
    echo '#!/bin/bash' > restartCachetmp.sh
    echo "cd $lancacheDIR/$lancacheDirectoryName" >> restartCachetmp.sh
    echo 'docker-compose restart' >> restartCachetmp.sh
    echo 'sleep 15' >> restartCachetmp.sh
    echo 'reboot' >> restartCachetmp.sh
    chmod +x restartCachetmp.sh
    (crontab -l; echo "0 3 * * * root $lancacheDIR/$lancacheDirectoryName/restartCache.sh") | sort -u | crontab -
}

# Starting lancache and downloading lancache docker images
startLancache() {
    cd $lancacheDIR/$lancacheDirectoryName
    clear && echo -e "\n\t${DARK_GRAY}Starting Lancache...${NoColor}" && sleep 3
    docker-compose up -d
}

# Renaming the restartCache script to the correct name, this is to prevent issues during setup process.
restartScriptRename() {
    cd $lancacheDIR/$lancacheDirectoryName 
    mv restartCachetmp.sh restartCache.sh
}

runSystemUpdates
installDocker
lancacheSetup
lancacheAutoRestart
startLancache
restartScriptRename
