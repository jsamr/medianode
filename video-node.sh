#!/bin/bash
#Make path relative
cd "${BASH_SOURCE%/*}" || exit 1
#Execute as user $1 in group $2
sudo -u $1 -g $2 coffee src/app.coffee