#Author: Gilles Biagomba
#Program: WeakSSL.sh
#Description: This script was design to check for weak SSL ciphers.\n
#Convert XML files to HTML
#xsltproc <nmap-output.xml> -o <nmap-output.html> 

#Initializing all variables 
declare -a PORT=(0 22 25 143 443 445 567 587 593 636 808 993 1159 1311 1392 1433 3071 3131 3132 3269 3389 3872 4443 4444 4848 4903 5556 5671 5672 5989 6701 6703 7002 7004 7101 7102 7103 7201 7202 7301 7403 7444 7501 7777 7799 7802 8000 8082 8089 8090 8140 8191 8443 8444 8834 8888 8889 8899 9002 9095 9096 9097 9098 9099 9100 9443 9999 10000 10109 10443 10571 12443 17169 23051 31100 32100 49203 49223 49693 49926 55443 56182 57572 58630 60306 63002 65298)
declare -a Ciphers=(DES-CBC-SHA DES-CBC3-SHA ECDH-ECDSA-DES-CBC3-SHA ECDH-ECDSA-RC4-SHA ECDH-RSA-DES-CBC3-SHA ECDH-RSA-RC4-SHA ECDHE-ECDSA-DES-CBC3-SHA ECDHE-ECDSA-RC4-SHA ECDHE-RSA-DES-CBC3-SHA ECDHE-RSA-RC4-SHA EDH-DSS-DES-CBC-SHA EDH-DSS-DES-CBC3-SHA EDH-RSA-DES-CBC-SHA EDH-RSA-DES-CBC3-SHA PSK-3DES-EDE-CBC-SHA PSK-AES128-CBC-SHA PSK-AES256-CBC-SHA PSK-RC4-SHA RC4-MD5 RC4-SHA SRP-3DES-EDE-CBC-SHA SRP-AES-128-CBC-SHA SRP-AES-256-CBC-SHA SRP-DSS-3DES-EDE-CBC-SHA SRP-DSS-AES-128-CBC-SHA SRP-DSS-AES-256-CBC-SHA SRP-RSA-3DES-EDE-CBC-SHA SRP-RSA-AES-128-CBC-SHA SRP-RSA-AES-256-CBC-SHA)
pth=$(pwd)
RunTIME=$(date +%H:%M)
STAT1="Up"
STAT2="open"
STAT3="filtered"
TodaysDAY=$(date +%m-%d)
TodaysYEAR=$(date +%Y)
wrkpth="$TodaysYEAR/$TodaysDAY"

#Requesting target file name
echo "What is the name of the targets file? The file with all the IP addresses"
read targets

#Creating workspace
echo "--------------------------------------------------"
echo "Creating the workspace"
echo "--------------------------------------------------"
cd $pth
mkdir -p $wrkpth/SSLScan $wrkpth/SSLyze $wrkpth/Cipherscan $wrkpth/Nmap
mkdir -p $wrkpth/TestSSL $wrkpth/WeakSSL $wrkpth/Reports $wrkpth/SSH-Audit
echo "Done creating workspace"

Nmap Scan
echo "--------------------------------------------------"
echo "Performing the SSL scan using Nmap"
echo "--------------------------------------------------"
nmap -sS -sV --script=ssh2-enum-algos,ssl-enum-ciphers,rdp-enum-encryption,vulners -R -iL $targets -p $(echo ${PORT[*]} | sed 's/ /,/g') -oA $pth/$wrkpth/Nmap/WeakSSL
xsltproc $pth/$wrkpth/Nmap/WeakSSL.xml -o $pth/$wrkpth/Reports/Nmap_SSL_Output.html
cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep Up | cut -d ' ' -f 2 > $pth/$wrkpth/Nmap/live
cat $pth/$wrkpth/Nmap/live | sort | uniq > $pth/$wrkpth/livehosts
echo "Done scanning with nmap"

function pause()
{
   read -p "$*"
}

# head $pth/$wrkpth/Nmap/WeakSSL.gnmap
# echo
# pause 'Press [Enter] key to continue...'

#SSL Scan
echo "--------------------------------------------------"
echo "Performing the SSL scan using sslscan"
echo "--------------------------------------------------"
for IP in $(cat $pth/$wrkpth/livehosts); do
    for PORTNUM in ${PORT[*]};do
        STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo "--------------------------------------------------" | aha -t "SSLScan Output" >> $pth/$wrkpth/Reports/sslscan_output.html
            echo "Using sslscan to scan $IP:$PORTNUM" | aha -t "SSLScan Output" >> $pth/$wrkpth/Reports/sslscan_output.html
            echo "$(date)" | aha -t "SSLScan Output" >> $pth/$wrkpth/Reports/sslscan_output.html
            echo "Using sslscan to scan $IP:$PORTNUM"            
            echo "--------------------------------------------------" | aha -t "SSLScan Output" >> $pth/$wrkpth/Reports/sslscan_output.html
            sslscan --xml=$pth/$wrkpth/SSLScan/sslscan_output.xml --ssl3 --tls10 --tls11 $IP:$PORTNUM | aha -t "SSLScan Output" >> $pth/$wrkpth/Reports/sslscan_output.html
        fi
    done
done
echo "Done scanning with sslscan"

#SSLyze Scan
echo "--------------------------------------------------"
echo "Performing the SSL scan using sslyze"
echo "--------------------------------------------------"
for IP in $(cat $pth/$wrkpth/livehosts); do
    for PORTNUM in ${PORT[*]};do
        STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo "--------------------------------------------------" | aha -t "SSLyze Output" >> $pth/$wrkpth/Reports/sslyze_output.html
            echo "Using sslyze to scan $IP:$PORTNUM" | aha -t "SSLyze Output" >> $pth/$wrkpth/Reports/sslyze_output.html
            echo "$(date)" | aha -t "SSLyze Output" >> $pth/$wrkpth/Reports/sslyze_output.html
            echo "Using sslyze to scan $IP:$PORTNUM"
            echo "--------------------------------------------------" | aha -t "SSLyze Output" >> $pth/$wrkpth/Reports/sslyze_output.html
            sslyze --xml_out=$pth/$wrkpth/SSLyze/SSLyze.xml --regular  --sslv3 --tlsv1 --tlsv1_1 $IP:$PORTNUM | aha -t "SSLyze Output"  >> $pth/$wrkpth/Reports/sslyze_output.html
        fi
    done
done
echo "Done scanning with sslyze"

#TestSSL Scan
echo "--------------------------------------------------"
echo "Performing the SSL scan using testssl"
echo "--------------------------------------------------"
cd $pth/$wrkpth/TestSSL/
for IP in $(cat $pth/$wrkpth/livehosts); do
    for PORTNUM in ${PORT[*]};do
        STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo "--------------------------------------------------" | aha -t "TestSSL Output" >> $pth/$wrkpth/Reports/testssl_output.html
            echo "Using testssl to scan $IP:$PORTNUM" | aha -t "TestSSL Output" >> $pth/$wrkpth/Reports/testssl_output.html
            echo "$(date)" | aha -t "TestSSL Output" >> $pth/$wrkpth/Reports/testssl_output.html
            echo "Using testssl to scan $IP:$PORTNUM"
            echo "--------------------------------------------------" | aha -t "TestSSL Output" >> $pth/$wrkpth/Reports/testssl_output.html
            testssl --outfile "$pth/$wrkpth/TestSSL/" --append $IP:$PORTNUM | aha -t "TestSSL output"  >> $pth/$wrkpth/Reports/testssl_output.html
        fi
    done
done
cd $pth/$wrkpth/
echo "Done scanning with testssl"

#Mozilla Cipherscan
echo "--------------------------------------------------"
echo "Performing the SSL scan using cipherscan"
echo "--------------------------------------------------"
cd /tmp/
git clone https://github.com/mozilla/cipherscan
cd cipherscan/
for IP in $(cat $pth/$wrkpth/livehosts); do
    for PORTNUM in ${PORT[*]};do
        STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            echo "--------------------------------------------------" | aha -t "Cipherscan Output" >> $pth/$wrkpth/Reports/CipherScan_output.html
            echo "Using cipherscan to scan $IP:$PORTNUM" | aha -t "Cipherscan Output" >> $pth/$wrkpth/Reports/CipherScan_output.html
            echo "$(date)" | aha -t "Cipherscan Output" >> $pth/$wrkpth/Reports/CipherScan_output.html
            echo "Using cipherscan to scan $IP:$PORTNUM"
            echo "--------------------------------------------------" | aha -t "Cipherscan Output" >> $pth/$wrkpth/Reports/CipherScan_output.html
            bash cipherscan https://$IP:$PORTNUM | aha -t "Cipherscan output"  > $pth/$wrkpth/Cipherscan/$IP-$PORTNUM-Cipherscan_detailed_output.html
            python2 analyze -t $IP:$PORTNUM | aha -t "Cipherscan output"  >> $pth/$wrkpth/Reports/CipherScan_output.html
        fi
    done
done
echo "Done scanning with cipherscan"

# #Mozilla SSH Audit
# echo "--------------------------------------------------"
# echo "Performing the SSL scan using SSH Audit"
# echo "--------------------------------------------------"
# cd /tmp/
# git clone https://github.com/arthepsy/ssh-audit
# cd ssh-audit/
# for IP in $(cat $pth/$wrkpth/livehosts); do
#     for PORTNUM in ${PORT[*]};do
#         STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
#         STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
#         STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
#         if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
#             echo "--------------------------------------------------" | aha -t "SSH-Audit Output" >> $pth/$wrkpth/SSH-Audit/$IP-SSH-Audit_detailed_output.html
#             echo "Using ssh-audit to scan $IP:$PORTNUM" | aha -t "SSH-Audit Output" >> $pth/$wrkpth/SSH-Audit/$IP-SSH-Audit_detailed_output.html
#             echo "$(date)" | aha -t "SSH-Audit Output" >> $pth/$wrkpth/SSH-Audit/$IP-SSH-Audit_detailed_output.html
#             echo "Using ssh-audit to scan $IP:$PORTNUM"
#             echo "--------------------------------------------------" | aha -t "SSH-Audit Output" >> $pth/$wrkpth/SSH-Audit/$IP-SSH-Audit_detailed_output.html
#             bash ssh-audit.py $IP:$PORTNUM | aha -t "SSH-Audit output"  >> $pth/$wrkpth/SSH-Audit/$IP-SSH-Audit_detailed_output.html
#         fi
#     done
# done
# cd $pth
# echo "Done scanning with SSH audit"

#OpenSSL - Manually checking weak ciphers (Needs to be fixed)
echo "--------------------------------------------------"
echo "Validating results using OpenSSL"
echo "--------------------------------------------------"
cd $pth
for IP in $(cat $pth/$wrkpth/livehosts); do
    for PORTNUM in ${PORT[*]};do
        STAT1=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "Status: Up" -m 1 -o | cut -c 9-10)
        STAT2=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/open" -m 1 -o | grep "open" -o)
        STAT3=$(cat $pth/$wrkpth/Nmap/WeakSSL.gnmap | grep $IP | grep "$PORTNUM/filtered" -m 1 -o | grep "filtered" -o)
        if [ "$STAT1" == "Up" ] && [ "$STAT2" == "open" ] || [ "$STAT3" == "filtered" ]; then
            for ciphr in ${Ciphers[*]};do
                echo "---------------------------------------------SSLv3---------------------------------------------------------"
                echo "Address: $IP:$PORTNUM"
                echo "Cipher: $Ciphers"
                bash /tmp/cipherscan/openssl s_client -connect $IP:$PORTNUM -ssl3 -cipher $ciphr | aha -t "OpenSSL Scan" >> $pth/$wrkpth/WeakSSL/$IP-WeakCiphers.html
                echo "---------------------------------------------TLSv1---------------------------------------------------------"
                echo "Address: $IP:$PORTNUM"
                echo "Cipher: $Ciphers"
                bash /tmp/cipherscan/openssl s_client -connect $IP:$PORTNUM -tls1 -cipher $ciphr | aha -t "OpenSSL Scan" >> $pth/$wrkpth/WeakSSL/$IP-WeakCiphers.html
                echo "---------------------------------------------TLSv1.1-------------------------------------------------------"
                echo "Address: $IP:$PORTNUM"
                echo "Cipher: $Ciphers"
                bash /tmp/cipherscan/openssl s_client -connect $IP:$PORTNUM -tls1_1 -cipher $ciphr | aha -t "OpenSSL Scan" >> $pth/$wrkpth/WeakSSL/$IP-WeakCiphers.html
                echo "--------------------------------------------------"
            done
        fi
    done
done
cd $pth

echo "Done validating ciphers & We are done scanning everything!"

#Open reports in Firefox    
echo "--------------------------------------------------"
echo "Opening the results now"
echo "--------------------------------------------------"
firefox --new-tab $pth/$wrkpth/Reports/*.html

# Empty file cleanup
find $pth -size 0c -type f -exec rm -rf {} \;

#Deleting Temp files
rm -rf /tmp/cipherscan/ /tmp/ssh-audit/

#De-initialize all variables & set them to NULL
unset ciphr
unset pth
unset IP
unset PORT
unset PORTNUM
unset STAT1
unset STAT2
unset targets
unset wrkpth
set -u