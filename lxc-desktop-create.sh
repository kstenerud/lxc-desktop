#!/bin/bash

#IMAGE=ubuntu/xenial
IMAGE=ubuntu/bionic

declare -A DESKTOPS
declare -a DESKTOP_KEYS
function add_desktop {
    DESKTOPS[$1]=$2
    DESKTOP_KEYS+=( $1 )
}

add_desktop budgie   ubuntu-budgie-desktop
add_desktop cinnamon cinnamon-desktop-environment
add_desktop gnome    ubuntu-gnome-desktop
add_desktop kde      kubuntu-desktop
add_desktop lxde     lubuntu-desktop
add_desktop mate     ubuntu-mate-desktop
add_desktop ubuntu   ubuntu-desktop
add_desktop unity    ubuntu-unity-desktop
add_desktop xfce     xubuntu-desktop
add_desktop all      ${DESKTOPS[*]}

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

DESKTOP_KEY=$1
DESKTOP_PACKAGE=${DESKTOPS[$DESKTOP_KEY]}
CONTAINER=$2
USERNAME=$3
PASSWORD=$4

function list_desktops {
    echo "Desktop types:"
    for i in "${!DESKTOP_KEYS[@]}"; do echo "    ${DESKTOP_KEYS[$i]}"; done
}

if [ -z $CONTAINER ]; then
    echo "Creates a new LXC desktop container"
    echo
    echo "Usage: $0 <desktop type> <container name> [new user [password]]"
    echo
    echo "container name: What to name the container"
    echo "new user: If set, delete the default user \"ubuntu\" from the base $IMAGE image and create a new admin user"
    echo "password: The password to give the new user (default: same as user name)"
    list_desktops
    echo
    echo "Note: The default ubuntu image has an exiting user \"ubuntu\""
    exit 1
fi

if [ -z $DESKTOP_PACKAGE ]; then
	echo "$DESKTOP_KEY: unknown desktop type"
	echo
	list_desktops
	exit 1
fi

if [ -z $USERNAME ]; then
    USERNAME=
fi
if [ -z $PASSWORD ]; then
    PASSWORD=$USERNAME
fi

set -eu

function container_exec {
    lxc exec $CONTAINER -- $@
}

function install_package {
    set +u
    package=$1
    if [ -z $package ]; then
        package=
    fi
    set -u

    lxc exec $CONTAINER -- bash -c "(export DEBIAN_FRONTEND=noninteractive; apt install -y $package)"
}


echo "Creating LXC $DESKTOP_KEY desktop from $IMAGE named \"$CONTAINER\"..."

lxc init images:$IMAGE $CONTAINER -s default

lxc network attach br0 $CONTAINER default eth0
# Fix to make dbus work correctly on non-privileged containers
lxc config device add $CONTAINER fuse unix-char major=10 minor=229 path=/dev/fuse
lxc start $CONTAINER

# Force bluetooth to install and then disable it so that it doesn't break the install.
set +e
install_package bluez
set -e
container_exec systemctl disable bluetooth
install_package

install_package software-properties-common
container_exec add-apt-repository -y ppa:x2go/stable
container_exec apt update
install_package x2goserver x2goserver-xsession
install_package $DESKTOP_PACKAGE
container_exec apt remove -y light-locker

if ! [ -z $USERNAME ]; then
    echo "Creating user $USERNAME"
    lxc exec $CONTAINER -- useradd --create-home --shell /bin/bash --user-group --groups adm,sudo --password $(openssl passwd -1 -salt xyz "$PASSWORD") $USERNAME
    container_exec userdel ubuntu
else
    echo "No new user will be created."
fi

echo "Creating baseline snaphot"
lxc snapshot $CONTAINER baseline
