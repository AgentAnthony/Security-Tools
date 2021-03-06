#!/bin/bash
#Author: Gilles Biagomba
#Program: Birthday_test.sh
#Description: This script was design check for CVE-2016-2183, CVE-2016-6329.\n
# 	      Or aka Sweet32: Birthday attacks on 64-bit block ciphers in TLS/SSL and OpenVPN.\n
#	      https://sweet32.info/ \n


# Nmap Scan
echo "--------------------------------------------------"
echo "Performing the SSL scan using Nmap"
echo "--------------------------------------------------"
nmap -A -F -Pn -R -sS -sU -sV --script=ssl-enum-ciphers,vulners -iL targets -oA Swett_Thirty-two
xsltproc Swett_Thirty-two.xml -o Reports/Nmap_TLS_Output.html
cat Swett_Thirty-two.gnmap | grep Up | cut -d ' ' -f 2 > live

for c in $(cat targets); do
 for i in $(cat WeakCiphers.txt); do 
  echo "----------------------------------------------TLSv1--------------------------------------------------------"
  echo "Address: $c"
  echo "Cipher: $i"
  echo "-----------------------------------------------------------------------------------------------------------"
  openssl s_client -connect $c:443 -tls1 -cipher $i
  echo "----------------------------------------------TLSv1.1------------------------------------------------------"
  echo "Address: $c"
  echo "Cipher: $i"
  echo "-----------------------------------------------------------------------------------------------------------"
  openssl s_client -connect $c:443 -tls1_1 -cipher $i
  echo "---------------------------------------------TLSv1.2-------------------------------------------------------"
  echo "Address: $c"
  echo "Cipher: $i"
  echo "-----------------------------------------------------------------------------------------------------------"
  openssl s_client -connect $c:443 -tls1_2 -cipher $i
  echo "-----------------------------------------------------------------------------------------------------------"
 done
done
