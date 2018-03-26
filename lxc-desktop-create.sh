#!/bin/bash

# =============
# Configuration
# =============

#SOURCE_IMAGE=ubuntu/xenial
SOURCE_IMAGE=ubuntu/bionic
USERNAME=ubuntu
STORAGE_POOL=default
CONTAINER_NAME=
PASSWORD=
HOME_MOUNT=
BRIDGE=br0
IS_PRIVILEGED=false
CREATE_BASELINE_SNAPSHOT=false

declare -A DESKTOPS
declare -a DESKTOP_KEYS
function add_desktop {
    DESKTOPS[$1]=$2
    DESKTOP_KEYS+=( $1 )
}
add_desktop budgie   "ubuntu-budgie-desktop gnome-settings-daemon gnome-session"
add_desktop cinnamon cinnamon-desktop-environment
add_desktop gnome    ubuntu-gnome-desktop
add_desktop kde      kubuntu-desktop
add_desktop lxde     lubuntu-desktop
add_desktop mate     ubuntu-mate-desktop
add_desktop ubuntu   ubuntu-desktop
add_desktop unity    ubuntu-unity-desktop
add_desktop xfce     xubuntu-desktop
add_desktop all      ${DESKTOPS[*]}



# =========
# Functions
# =========

error() {
    set +eu
    local parent_lineno="$1"
    local message="$2"
    local code="${3:-1}"
    if [[ -n "$message" ]] ; then
        echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
    else
        echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
    fi
    exit "${code}"
}
trap 'error ${LINENO}' ERR

function list_desktops {
    for i in "${!DESKTOP_KEYS[@]}"; do echo "    ${DESKTOP_KEYS[$i]}"; done
}

function show_help {
    echo "Create a new LXC desktop container"
    echo
    echo "Usage: $0 [options] <desktop type>"
    echo
    echo "Options:"
    echo "    -?: Show this help screen."
    echo "    -u username: The desktop username to create (default ubuntu)."
    echo "    -p password: The password for the desktop user (default same as username)."
    echo "    -n name: The container's name (default same as desktop type)."
    echo "    -h path: Mount an external directory as the user's home directory."
    echo "    -p: Make a privileged container. Recommended when using -h to avoid ownership issues."
    echo "    -s pool: Use the specified storage pool (default \"default\")."
    echo "    -S: Create a baseline snapshot of the container."
    echo "    -i image: The source image to build the container from - only ubuntu images will work (default ubuntu/bionic)."
    echo "    -b bridge: The bridge to connect the container to as eth0 (default br0)."
    echo
    echo "Desktop types: "
    list_desktops
}

function container_exec {
    lxc exec $CONTAINER_NAME -- $@
}

function create_user {
    username=$1
    password=$2
    echo "Creating user $username"
    lxc exec $CONTAINER_NAME -- useradd --create-home --shell /bin/bash --user-group --groups adm,sudo --password $(openssl passwd -1 -salt xyz "$password") $username
}

function delete_user {
    username=$1
    container_exec userdel -r $username
}

function install_package {
    set +u
    package=$1
    if [ -z $package ]; then
        package=
    fi
    set -u

    lxc exec $CONTAINER_NAME -- bash -c "(export DEBIAN_FRONTEND=noninteractive; apt install -y $package)"
}

function prepare_options {
    DESKTOP_PACKAGE=${DESKTOPS[$DESKTOP_KEY]}
    if [ -z $DESKTOP_PACKAGE ]; then
        echo "$DESKTOP_KEY: unknown desktop type"
        echo
        echo "Recognized desktop types:"
        list_desktops
        exit 1
    fi

    if [ -z $PASSWORD ]; then
        PASSWORD=$USERNAME
    fi

    if [ -z $CONTAINER_NAME ]; then
        CONTAINER_NAME=$DESKTOP_KEY
    fi
}

function create_container {
    echo "Creating LXC $DESKTOP_KEY desktop from $SOURCE_IMAGE"
    lxc init images:$SOURCE_IMAGE $CONTAINER_NAME -s $STORAGE_POOL

    if [ "$IS_PRIVILEGED" = true ]; then
        lxc config set $CONTAINER_NAME security.privileged true
    fi

    lxc network attach $BRIDGE $CONTAINER_NAME default eth0

    # Fix to make dbus work correctly on non-privileged containers
    lxc config device add $CONTAINER_NAME fuse unix-char major=10 minor=229 path=/dev/fuse

    lxc start $CONTAINER_NAME
    delete_user ubuntu
    create_user $USERNAME "$PASSWORD"

    if ! [ -z $HOME_MOUNT ]; then
        echo "Mounting home directory /home/$USERNAME from $HOME_MOUNT"
        lxc config device add $CONTAINER_NAME shareName disk source="$HOME_MOUNT" path=/home/$USERNAME
        container_exec chown $USERNAME:$USERNAME /home/$USERNAME
    fi
}

function fix_bluetooth {
    # Force bluetooth to install and then disable it so that it doesn't break the rest of the install.
    set +e
    install_package bluez
    set -e
    container_exec systemctl disable bluetooth
    install_package
}

function install_desktop {
    install_package $DESKTOP_PACKAGE
    container_exec apt remove -y light-locker
}

function install_x2go {
    install_package software-properties-common
    container_exec add-apt-repository -y ppa:x2go/stable
    container_exec apt update
    install_package x2goserver x2goserver-xsession
}

function install_chrome_remote_desktop {
    container_exec wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    container_exec apt install -y ./google-chrome-stable_current_amd64.deb
    container_exec rm google-chrome-stable_current_amd64.deb
    container_exec wget -q https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    container_exec apt install -y ./chrome-remote-desktop_current_amd64.deb
    container_exec rm chrome-remote-desktop_current_amd64.deb
}

function install_other_software {
    install_package transmission amule
}

function build_container {
    create_container
    fix_bluetooth
    install_desktop
    install_x2go
    install_chrome_remote_desktop
    install_other_software

    if [ "$CREATE_BASELINE_SNAPSHOT" = true ]; then
        echo "Creating baseline snaphot"
        lxc snapshot $CONTAINER_NAME baseline
    fi
}



# =======
# Options
# =======

OPTIND=1
while getopts "?u:p:n:h:pSs:i:b:" opt; do
    case "$opt" in
    \?)
        show_help
        exit 0
        ;;
    u)  USERNAME=$OPTARG
        ;;
    p)  PASSWORD=$OPTARG
        ;;
    n)  CONTAINER_NAME=$OPTARG
        ;;
    h)  HOME_MOUNT=$OPTARG
        ;;
    p)  IS_PRIVILEGED=true
        ;;
    S)  CREATE_BASELINE_SNAPSHOT=true
        ;;
    s)  STORAGE_POOL=$OPTARG
        ;;
    i)  SOURCE_IMAGE=$OPTARG
        ;;
    b)  BRIDGE=$OPTARG
        ;;
    esac
done
shift $((OPTIND-1))
[ "$1" = "--" ] && shift

DESKTOP_KEY=$1
if [ -z $DESKTOP_KEY ]; then
    show_help
    exit 1
fi

prepare_options



# =======
# Program
# =======

set -eu

build_container
