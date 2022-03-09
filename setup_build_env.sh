#!/bin/sh

#####################################################################
## Setup variables
#####################################################################

_ECHO=/usr/bin/echo
_INSTALL="/usr/bin/apt-get -y install"
_CP=/usr/bin/cp
_MOUNT=/usr/bin/mount
_CHROOT=/usr/sbin/chroot
_DEBOOTSTRAP=/usr/sbin/debootstrap
_CAT=/usr/bin/cat

_EXIT="exit 1"

_CHROOT_DIR=${1}


#####################################################################
## Install requred packages
#####################################################################

${_ECHO} "Installing dependencies"

for name in "qemu-user-static debootstrap"
do
    ${_INSTALL} ${name} || ${_EXIT}
done

${_ECHO} "Dependencies installation done."


#####################################################################
## Create root fs using debootstrap
#####################################################################

${_ECHO} "Creating root FS"
${_DEBOOTSTRAP} --no-check-gpg --foreign --arch=armhf buster ${_CHROOT_DIR} http://archive.raspbian.org/raspbian || ${_EXIT}

${_ECHO} "Copying QEMU static binary"
cp /usr/bin/qemu-arm-static ${_CHROOT_DIR}/usr/bin

${_ECHO} "Registering ARM binary format"
if [ -f /proc/sys/fs/binfmt_misc/arm ]
then
    ${_ECHO} "ARM binary format already registered"
else
    sudo ${_ECHO} ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:/usr/bin/qemu-arm-static:' >> /proc/sys/fs/binfmt_misc/register || ${_EXIT}
	${_ECHO} "ARM binary format registered"
fi

${_ECHO} "Running debootstrap second stage"
${_CHROOT} ${_CHROOT_DIR} /debootstrap/debootstrap --second-stage || ${_EXIT}

${_ECHO} "Setting up package management in guest environment"
${_CAT} > ${_CHROOT_DIR}/etc/apt/sources.list << EOF
deb http://mirrordirector.raspbian.org/raspbian/ buster main contrib non-free rpi
deb http://archive.raspberrypi.org/debian/ buster main
EOF

${_CHROOT} ${_CHROOT_DIR} apt-key adv --keyserver keyserver.ubuntu.com --recv 82B129927FA3303E || ${_EXIT}
${_CHROOT} ${_CHROOT_DIR} apt-get update || ${_EXIT}

${_ECHO} "Guest chroot environment is ready at ${_CHROOT_DIR}"

exit 0
