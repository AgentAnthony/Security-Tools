#!/usr/bin/env bash
# Based on this article https://ourcodeworld.com/articles/read/410/how-to-install-node-js-in-kali-linux

# Checking user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Ensuring system is debian based
OS_CHK=$(cat /etc/os-release | grep -o debian)
if [ "$OS_CHK" != "debian" ]; then
    echo "Unfortunately this install script was written for debian based distributions only, sorry!"
    exit
fi

# Verify that you have all required tools
apt-get install python g++ make checkinstall fakeroot -y

# You may get a warning like "dpkg was interrupted", the below command will correct it
# dpkg --configure -a

# Create tmp dir and switch to it
src=$(mktemp -d) && cd $src

# Download the latest version of Node
wget -N http://nodejs.org/dist/node-latest.tar.gz

# Extract the content of the tar file
tar xzvf node-latest.tar.gz && cd node-v*

# Run configuration
bash configure

# Create .deb for Node
sudo fakeroot checkinstall -y --install=no --pkgversion $(echo $(pwd) | sed -n -re's/.+node-v(.+)$/\1/p') make -j$(($(nproc)+1)) install

# Replace [node_*] with the name of the generated .deb package of the previous step
sudo dpkg -i node_*

# Checking npm to make sure it has been installed
node -v
