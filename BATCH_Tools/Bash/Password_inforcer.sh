#Author: Jerry Gamblin & Gilles Biagomba
#Program: Password_Inforcer.sh
#Description: This script is based on an article written bu Jerry Gamblin.\n
# 	      I (Gilles B) merely copied his instructions and turned it into.\n
#	      a script. For more details, please reference the link below.\n
#https://jerrygamblin.com/2017/08/24/disallow-million-most-common-passwords/

apt-get install libpam-cracklib -y
#git clone https://github.com/danielmiessler/SecLists
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt /usr/share/dict/ -O /usr/share/dict/million.txt
create-cracklib-dict /usr/share/dict/million.txt
