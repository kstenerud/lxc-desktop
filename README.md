LXC Desktop
===========

A script to create a full desktop environment inside a linux container.

You can access the desktop using x2go.


Usage
-----

    lxc-dektop-create.sh <desktop type> <container name> [new user [password]]

    desktop type: The type of desktop to create (lxde, mate, etc). Type lxc-dektop-create.sh by itelf for a list.
    container name: What to name the container.
    new user: If set, delete the default user "ubuntu" from the base image and create a new admin user.
    password: The password to give the new user (default: same as user name).

Notes
-----

The base ubuntu image has an existing "ubuntu" user. If you specify a new user, "ubuntu" will be deleted and replaced with it.
