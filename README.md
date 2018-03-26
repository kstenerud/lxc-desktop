LXC Desktop
===========

A script to create a full desktop environment inside a linux container.

You can access the desktop using x2go.


Requirements
------------

LXC 3.0+


Usage
-----

    lxc-desktop-create.sh [options] desktop-type

Options:

 * -?: Show this help screen.
 * -u username: The desktop username to create (default ubuntu).
 * -p password: The password for the desktop user (default same as username).
 * -n name: The container's name (default same as desktop type).
 * -h path: Mount an external directory as the user's home directory.
 * -p: Make a privileged container. Recommended when using -h to avoid ownership issues.
 * -s pool: Use the specified storage pool (default "default").
 * -S: Create a baseline snapshot of the container.
 * -i image: The source image to build the container from - only ubuntu images will work (default ubuntu/bionic).
 * -b bridge: The bridge to connect the container to as eth0 (default br0).

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


The State of Things
===================

Currently, only the following desktops actually work:

  * lxde
  * mate

The rest fail due to a dbus issue that I haven't been able to track down. Here are the logs if anyone has ideas:

### ~/.xsession-x2go-all-errors:

	dbus-update-activation-environment: warning: error sending to systemd: org.freedesktop.DBus.Error.Spawn.ChildExited: Process org.freedesktop.systemd1 exited with status 1
	xhost:  must be on local machine to add or remove hosts.
	localuser:karl being added to access control list
	xhost:  must be on local machine to add or remove hosts.
	dbus-update-activation-environment: setting QT_ACCESSIBILITY=1
	dbus-update-activation-environment: warning: error sending to systemd: org.freedesktop.DBus.Error.Spawn.ChildExited: Process org.freedesktop.systemd1 exited with status 1


### /var/log/syslog:

	Mar 26 11:34:14 all /usr/bin/x2gomountdirs[712]: successfully mounted karl@127.0.0.1:33574/home/karl/.x2go/S-karl-50-1522064053_stDGNOME_dp24/spool to /tmp/.x2go-karl/spool/C-karl-50-1522064053_stDGNOME_dp24
	Mar 26 11:34:15 all /usr/bin/x2goruncommand: launching session with Xsession-x2go mechanism, using STARTUP="/usr/bin/gnome-session --session=gnome-flashback-metacity --disable-acceleration-check"
	Mar 26 11:34:15 all /usr/bin/x2goruncommand: dbus wrapper available as /usr/bin/dbus-run-session
	Mar 26 11:34:15 all udisksd[155]: Error statting /dev/loop0: No such file or directory
	Mar 26 11:34:15 all udisksd[155]: Error statting none: No such file or directory
	Mar 26 11:34:16 all gnome-session[852]: gnome-session-binary[852]: CRITICAL: We failed, but the fail whale is dead. Sorry....
	Mar 26 11:34:16 all gnome-session-binary[852]: CRITICAL: We failed, but the fail whale is dead. Sorry....
	Mar 26 11:34:16 all udisksd[155]: Error statting /dev/loop0: No such file or directory
	Mar 26 11:34:16 all udisksd[155]: Error statting none: No such file or directory
	Mar 26 11:34:17 all udisksd[155]: Error statting /dev/loop0: No such file or directory
	Mar 26 11:34:17 all udisksd[155]: Error statting none: No such file or directory
	Mar 26 11:34:17 all /usr/bin/x2goumount-session[1106]: successfully unmounted "/tmp/.x2go-karl/spool/C-karl-50-1522064053_stDGNOME_dp24"
