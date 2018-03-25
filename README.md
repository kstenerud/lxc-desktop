LXC Desktop
===========

A script to create a full desktop environment inside a linux container.

You can access the desktop using x2go.


Usage
-----

    lxc-desktop-create.sh [options] desktop-type

Options:

 * -?: Show this help screen.
 * -u username: The desktop username to create (default ubuntu).
 * -p password: The password for the desktop user (default same as username).
 * -n name: The container's name (default same as desktop type).
 * -h path: Mount an external directory as the user's home directory.
 * -s pool: Use the specified storage pool (default "default").
 * -S: Create a baseline snapshot of the container.
 * -i image: The source image to build the container from - only ubuntu images will work (default ubuntu/bionic).

Desktop types: 

 * budgie
 * cinnamon
 * gnome
 * kde
 * lxde
 * mate
 * ubuntu
 * unity
 * xfce

