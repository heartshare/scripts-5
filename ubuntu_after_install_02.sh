#!/bin/bash

# Set ESCAPE on CapsLock
dconf write "/org/gnome/desktop/input-sources/xkb-options" "['caps:escape']"

# Git config
git config --global user.name "jezman"
git config --global user.email jez.studio@gmail.com

DIR=/tmp/distrib
mkdir $DIR
cd $DIR

wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

# Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
