#!/usr/bin/env bash

DIR='/etc/sudoers.d/'
FILE=$DIR'vagrant-syncedfolders'

if [ ! -d "$DIR" ]; then
  sudo mkdir $DIR
fi
if [ ! -f "$FILE" ]; then
  sudo tee -a $FILE >/dev/null <<EOF
Cmnd_Alias VAGRANT_EXPORTS_ADD = /usr/bin/tee -a /etc/exports
Cmnd_Alias VAGRANT_NFSD = /sbin/nfsd restart
Cmnd_Alias VAGRANT_EXPORTS_REMOVE = /usr/bin/sed -E -e /*/ d -ibak /etc/exports
%admin ALL=(root) NOPASSWD: VAGRANT_EXPORTS_ADD, VAGRANT_NFSD, VAGRANT_EXPORTS_REMOVE
EOF
fi
