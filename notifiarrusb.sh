#!/bin/bash

set -euo pipefail

#Disclaimer

printf "\033[0;31mDisclaimer: This installer is unofficial and Ultra.cc staff will not support any issues with it.\033[0m\n"
read -rp "Type confirm if you wish to continue: " input
if [ ! "$input" = "confirm" ]; then
    exit
fi

clear

cd "${HOME}" || exit 1

#Functions

port_picker() {
  port=''
  while [ -z "${port}" ]; do
    echo "Listing free ports.."
    app-ports free
    echo "Pick any application from the list above, that you do not plan to use in the future."
    echo "We'll be using this port for notifiarr."
    read -rp "$(tput setaf 4)$(tput bold)Application name in full[Example: pyload]: $(tput sgr0)" appname
    proper_app_name=$(app-ports show | grep -i "${appname}" | head -n 1 | cut -c 7-) || proper_app_name=''
    port=$(app-ports show | grep -i "${appname}" | head -n 1 | awk '{print $1}') || port=''
    if [ -z "${port}" ]; then
      echo "$(tput setaf 1)Invalid choice! Please choose an application from the list and avoid typos.$(tput sgr0)"
      echo "$(tput bold)Listing all applications again..$(tput sgr0)"
      sleep 6
      clear
    fi
  done
  echo "$(tput setaf 2)Are you sure you want to use ${proper_app_name}'s port? type 'confirm' to proceed.$(tput sgr0)"
  read -r input
  if [ ! "${input}" = "confirm" ]; then
    exit
  fi
  echo
}

media_server(){

    plexport=$(app-ports show | grep "Plex Media Server" | head -n 1 | awk '{print $1}') || plexport=''
    embyport=$(app-ports show | grep "Emby" | head -n 1 | awk '{print $1}') || embyport=''
    jellyport=$(app-ports show | grep "Jellyfin" | head -n 1 | awk '{print $1}') || jellyport=''

    echo
    echo "Which media server are you planning to use notifiarr with?"

    select server in "Plex Media Server" "Emby" "Jellyfin"; do

        case ${server} in
            "Plex Media Server")
                target='plex'
                target2='emby'
                target3='jellyfin'
                serverport="${plexport}"
                url="http://172.17.0.1:${serverport}"
                url2="http://172.17.0.1:${embyport}"
                url3="http://172.17.0.1:${jellyport}/jellyfin"
                auth="${url}/?X-Plex-Token"
                break
                ;;
            "Emby")
                target='emby'
                target2='plex'
                target3='jellyfin'
                serverport="${embyport}"
                url="http://172.17.0.1:${serverport}"
                url2="http://172.17.0.1:${plexport}"
                url3="http://172.17.0.1:${jellyport}/jellyfin"
                auth="${url}/System/Info?Api_key"
                break
                ;;
            "Jellyfin")
                target='jellyfin'
                target2='plex'
                target3='emby'
                serverport="${jellyport}"
                url="http://172.17.0.1:${serverport}/jellyfin"
                url2="http://172.17.0.1:${plexport}"
                url3="http://172.17.0.1:${embyport}"
                auth="${url}/System/Info?Api_key"
                break
                ;;
            *)
                echo "ERROR: Invalid option $REPLY. Input [ 1 - 3 ]."
                ;;
        esac
    done

    [ "${serverport}" = '' ] && {
        echo "ERROR: ${server} port not found."
        exit 1
    }

    while true; do
        echo
        read -rp "Enter the ${server} authentication token: " servertoken
        echo
        curl -fs "${auth}=${servertoken}" > /dev/null && break
        echo "ERROR: ${server} authentication failed, try again."
    done
}

latest_version() {
    mkdir -p "${HOME}/.apps/notifiarr"
    echo "Getting latest version of notifiarr..."
    LATEST_RELEASE=$(curl -s https://github.com/Notifiarr/notifiarr/releases/latest | grep download | grep linux_amd64 | cut -d\" -f4)
    mkdir -p "${HOME}/.notifiarr-tmp"
    wget -qO "${HOME}/.notifiarr-tmp/notifiarr" "${LATEST_RELEASE}" || {
        echo "Failed to get latest release of notifiarr."
        rm -rf "${HOME}/.notifiarr-tmp"
        exit 1
    }
    rm -rf "${HOME}/bin/notifiarr"
    cp "${HOME}/.notifiarr-tmp/notifiarr" "${HOME}/bin/" && chmod +x "${HOME}/bin/notifiarr"
    rm -rf "${HOME}/.autoscan-tmp"
}

get_password() {
  while true; do
    read -rsp "The password for notifiarr: " password
    echo
    read -rsp "The password for notifiarr (again): " password2
    echo
    [ "${password}" = "${password2}" ] && break
    echo "ERROR: Passwords didn't match, try again."
  done
}
