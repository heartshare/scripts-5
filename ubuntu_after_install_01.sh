#/bin/bash

# Run script as sudo!
if [ "$EUID" -ne 0 ]
  then echo "Are you fucking crazy??? USE SUDO..."
  exit
fi

# Input username
echo 'Input your username: '
read USR
grep "$USR" /etc/passwd >/dev/null
  if [ $? -ne 0 ]; then
    echo 'No username found'
  fi

echo "$USER ALL=(ALL) NOPASSWD:ALL" > /dev/null | tee -a /etc/sudoers

DIR=/tmp/distrib
mkdir $DIR
cd $DIR

# Install Atom
wget https://github.com/atom/atom/releases/download/v1.11.2/atom-amd64.deb
dpkg -i atom-amd64.deb

# Install Veracrypt
wget https://launchpad.net/veracrypt/trunk/1.19/+download/veracrypt-1.19-setup.tar.bz2
tar -xjf veracrypt-1.19-setup.tar.bz2
./varacry

# Install Dropbox
wget https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_2015.10.28_amd64.deb
dpkg -i dropbox_2015.10.28_amd64.deb

# Install atom packages
apm install autocomplete-python linter linter-pycodestyle go-plus go-debug\
  vim-mode language-docker minimap minimap-highlight-selected todo-show tool-bar \
  file-icons atom-alignment atom-material-syntax atom-material-ui  \
# Vivacious themes repo
add-apt-repository ppa:ravefinity-project -y

# Install ubuntu packages
apt-get update
apt-get install nmap zsh htop ipcalc ipython iotop tor privoxy redshift \
  iftop keepassx openvpn sshfs network-manager-openvpn-gnome vlc \
  ruby ruby-dev torbrowser-launcher unity-tweak-tool mc wine wireshark \
  compizconfig-settings-manager gparted vim kvm libvirt-bin curl git clang \
  vivacious-unity-gtk-dark chromium-browser preload gufw virt-manger \
  vivacious-folder-colors-addon -y
apt-get upgrade -y

# Add user to group
adduser $USR kvm
adduser $USR libvirtd

# Install Katoolin - kali repo tools
git clone https://github.com/LionSec/katoolin.git
mv katoolin/katoolin.py ~/bin/katoolin
chmod +x ~/bin/katoolin

# Privoxy setting
cat <<EOF >> /etc/privoxy/conf
forward-socks5 / localhost:9050 .
forward-socks4 / localhost:9050 .
forward-socks4a / localhost:9050 .
EOF

# Tor services
update-rc.d -f tor remove && update-rc.d -f tor defaults && update-rc.d -f \
  privoxy remove && update-rc.d -f privoxy defaults && update-rc.d -f \
  privoxy enable

# Anti redeyes effect
redshift -l 37:-6 -t 3500:3500 &

# Install PlatformIO
python -c "$(curl -fsSL https://raw.githubusercontent.com/platformio/platformio/master/scripts/get-platformio.py)"
