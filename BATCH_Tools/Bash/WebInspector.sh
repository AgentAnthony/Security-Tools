# Author: Gilles Biagomba
# Program:Web Inspector
# Description: This script is designed to automate the earlier phases.\n
#              of a web application assessment (specficailly recon).\n

# to do list:
# add sniper
# uninitialize variables
# add multithread paralell processing
# move all subroutines into functions
# limit amount of data stored to disk, use more variables

# Declaring variables
n=0
pth=$(pwd)
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$pth/$TodaysYEAR/$TodaysDAY"

# Setting Envrionment
mkdir -p  $wrkpth/Halberd/ $wrkpth/Sublist3r/ $wrkpth/Harvester $wrkpth/Metagoofil
mkdir -p $wrkpth/Nikto/ $wrkpth/Dirb/ $wrkpth/Nmap/ $wrkpth/Sniper/
mkdir -p $wrkpth/Masscan/

# Checking dependencies - halberd, sublist3r, theharvester, metagoofil, nikto, dirb, nmap, sn1per and masscan
if [ "halberd" != "$(ls /usr/local/bin/ | grep halberd)" ]; then
    cd /opt/
    git clone https://github.com/jmbr/halberd
    cd halberd
    python setup.py install
fi

if [ "sublist3r" != "$(ls /usr/bin/ | grep sublist3r)" ]; then
    apt install sublist3r -y
fi

if [ "theharvester" != "$(ls /usr/bin/ | grep theharvester)" ]; then
    apt install theharvester -y
fi

if [ "metagoofil" != "$(ls /usr/bin/ | grep metagoofil)" ]; then
    apt install metagoofil -y
fi

if [ "nikto" != "$(ls /usr/bin/ | grep nikto)" ]; then
    apt install nikto -y
fi

if [ "dirb" != "$(ls /usr/bin/ | grep dirb)" ]; then
    apt install dirb -y
fi

if [ "nmap" != "$(ls /usr/bin/ | grep nmap)" ]; then
    apt install nmap -y
fi

if [ "sniper" != "$(ls /usr/bin/ | grep sniper)" ]; then
    cd /opt/
    git clone https://github.com/1N3/Sn1per
    cd Sn1per
    bash install,sh
fi

if [ "masscan" != "$(ls /usr/bin/ | grep masscan)" ]; then
    apt install masscan -y
fi

if [ "html2text" != "$(ls /usr/bin/ | grep html2text)" ]; then
    apt install html2text -y
fi

# Moving back to original workspace
clear
cd $pth

# Requesting target file name & moving to work space
echo "What is the name of the targets file? The file with all the IP addresses or sites"
read targets

if [ "$targets" != "$(ls $pth | grep $targets)" ]; then
    echo "File not found! Try again!"
    exit
fi

# Parsing the target file
cat $targets | grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" > WebTargets
cat $targets | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" > temptargets
cat $targets | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\/[0-9]\{1,\}'  >> temptargets
cat temptargets | sort | uniq > IPtargets
echo

# Using sublist3r 
echo "--------------------------------------------------"
echo "Performing scan using Sublist3r"
echo "--------------------------------------------------"
for web in $(cat $pth/WebTargets);do
	sublist3r -d $web -v -t 10 -o $wrkpth/Sublist3r/sublist3r_output-"$((++n))"
done
cat $wrkpth/Sublist3r/sublist3r_output* > TempWeb
cat WebTargets >> TempWeb
cat TempWeb | sort | uniq > WebTargets
echo 

# Using halberd
echo "--------------------------------------------------"
echo "Performing scan using Halberd"
echo "--------------------------------------------------"
halberd -u $pth/WebTargets -o $wrkpth/Halberd/halberd_output
grep $wrkpth/Halberd/halberd_output | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> temptargets
cat temptargets | sort | uniq > IPtargets
echo

# Using theharvester & metagoofil
echo "--------------------------------------------------"
echo "Performing scan using Theharvester and Metagoofil"
echo "--------------------------------------------------"
n=0
x=0
for web in $(cat $pth/WebTargets);do
    theharvester -d $web -l 500 -b all -h | tee $wrkpth/Harvester/harvester_output-"$((++n))"
    metagoofil -d $web -l 500 -o $wrkpth/Harvester/Evidence -f $wrkpth/Harvester/metagoofil_output-"$((++x))".html -t pdf,doc,xls,ppt,odp,od5,docx,xlsx,pptx
    # wait
done
cat harvester_output-* | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" >> temptargets
cat harvest_output-* |grep -E "(\.gov|\.us|\.net|\.com|\.edu|\.org|\.biz)" | cut -d ":" -f 1 >> TempWeb
cat WebTargets >> TempWeb
cat IPtargets >> temptargets
cat TempWeb | sort | uniq > WebTargets
cat temptargets | sort | uniq > IPtargets

# Parsing PDF documents
echo "--------------------------------------------------"
echo "Parsing all the PDF documents found"
echo "--------------------------------------------------"
#add a if statement to make sure the directory isnt empty, so if it is you can skip this step
for files in $(ls $wrkpth/Harvester/Evidence/ | grep pdf);do
    pdfinfo $files.pdf | grep Author | cut -d " " -f 10 | tee -a $wrkpth/Harvester/tempusr
done
cat $wrkpth/Harvester/tempusr | sort | uniq > Usernames
echo

# Using nikto & dirb
echo "--------------------------------------------------"
echo "Performing scan using Nikto and Dirb"
echo "--------------------------------------------------"
n=0
x=0
for web in $(cat $pth/WebTargets);do
    nikto -C all -h https://$web -o Nikto_Output-"$((++n))"
    dirb $web /usr/share/dirbuster/wordlists/directory-list-1.0.txt -o dirb_output-"$((++x))" -w	
done
echo

# Using masscan to perform a quick port sweep
echo "--------------------------------------------------"
echo "Performing scan using Masscan"
echo "--------------------------------------------------"
masscan -iL $pth/IPtargets -p 0-65535 --open-only --banners -oL $wrkpth/Masscan/masscan_output
cat $wrkpth/Masscan/masscan_output | cut -d " " -f 4 | grep -v masscan | sort | uniq >> $wrkpth/livehosts
OpenPORT=($(cat $wrkpth/Masscan/masscan_output | cut -d " " -f 3 | grep -v masscan | sort | uniq))
echo 

# Combining target giles
echo "--------------------------------------------------"
echo "Merging all targets files"
echo "--------------------------------------------------"
cat $pth/IPtargets > $pth/FinalTargets
cat $pth/WebTargets > $pth/FinalTargets
echo

# Using Nmap
echo "--------------------------------------------------"
echo "Performing scan using Nmap"
echo "--------------------------------------------------"

# Nmap - Pingsweep using ICMP echo
nmap -sP -PE -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmpecho
cat $wrkpth/Nmap/icmpecho.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmpecho.xml -o $wrkpth/Nmap/icmpecho.html
echo

# Nmap - Pingsweep using ICMP timestamp
nmap -sP -PP -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmptimestamp
cat $wrkpth/Nmap/icmptimestamp.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmptimestamp.xml -o $wrkpth/Nmap/icmptimestamp.html
echo

# Nmap - Pingsweep using ICMP netmask
nmap -sP -PM -iL $pth/FinalTargets -oA $wrkpth/Nmap/icmpnetmask
cat $wrkpth/Nmap/icmpnetmask.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/icmpnetmask.xml -o $wrkpth/Nmap/icmpnetmask.html
echo

# Systems that respond to ping (finding)
cat $wrkpth/Nmap/live | sort | uniq > $wrkpth/Nmap/pingresponse
echo

# Nmap - Pingsweep using TCP SYN and UDP
nmap -sP -PS 21,22,23,25,53,80,88,110,111,135,139,443,445,8080 -iL $pth/FinalTargets -oA $wrkpth/Nmap/pingsweepTCP
nmap -sP -PU 53,111,135,137,161,500 -iL $pth/FinalTargets -oA $wrkpth/Nmap/pingsweepUDP
cat $wrkpth/Nmap/pingsweepTCP.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
cat $wrkpth/Nmap/pingsweepUDP.gnmap | grep Up | cut -d ' ' -f 2 >> $wrkpth/Nmap/live
xsltproc $wrkpth/Nmap/pingsweepTCP.xml -o $wrkpth/Nmap/pingsweepTCP.html
xsltproc $wrkpth/Nmap/pingsweepUDP.xml -o $wrkpth/Nmap/pingsweepUDP.html
echo

# Nmap - Full TCP SYN scan on live targets
nmap -A -Pn -R -sS -sV -p $(echo ${OpenPORT[*]} | sed 's/ /,/g') --script=ssl-enum-ciphers,vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/TCPdetails
xsltproc $wrkpth/Nmap/TCPdetails.xml -o $wrkpth/Nmap/Nmap_Output.html
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 25/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMTP
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 53/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/DNS
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 23/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/telnet
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 445/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/SMB
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ' 139/open' | cut -d ' ' -f 2 > $wrkpth/Nmap/netbios
cat $wrkpth/Nmap/TCPdetails.gnmap | grep http | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/http
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/ssh
cat $wrkpth/Nmap/TCPdetails.gnmap | grep ssl | grep open | cut -d ' ' -f 2 > $wrkpth/Nmap/ssl
cat $wrkpth/Nmap/TCPdetails.gnmap | grep Up | cut -d ' ' -f 2 > $wrkpth/Nmap/live
cat $wrkpth/Nmap/live | sort | uniq >> $wrkpth/livehosts
echo

# Nmap - Default UDP scan on live targets
nmap -sU -PN -T4 -iL $pth/FinalTargets -oA $wrkpth/Nmap/UDPdetails
cat $pth/UDPdetails.gnmap | grep ' 161/open\?\!|' | cut -d ' ' -f 2 > $pth/SNMP
cat $pth/UDPdetails.gnmap | grep ' 500/open\?\!|' | cut -d ' ' -f 2 > $pth/isakmp
xsltproc $wrkpth/Nmap/UDPdetails.xml -o $wrkpth/Nmap/UDPdetails.html
echo

# Nmap - Firewall evasion
nmap -f -mtu 24 --spoof-mac Dell --randomize-hosts -A -Pn -R -sS -sU -sV --script=vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/FW_Evade
nmap -D RND:10 --badsum --data-length 24 --randomize-hosts -A -Pn -R -sS -sU -sV --script=vulners -iL $pth/FinalTargets -oA $wrkpth/Nmap/FW_Evade2
xsltproc $wrkpth/Nmap/FW_Evade.xml -o $wrkpth/Nmap/FW_Evade.html
xsltproc $wrkpth/Nmap/FW_Evade2.xml -o $wrkpth/Nmap/FW_Evade2.html
echo

# Empty file cleanup
find $pth -size 0c -type f -exec rm -rf {} \;

# Removing unnessary files
rm IPtargets -f
rm temptargets -f
rm tempusr -f
rm TempWeb -f
rm WebTargets -f

# Uninitializing variables
# do later
set -u
