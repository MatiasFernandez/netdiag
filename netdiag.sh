#!/bin/bash

# ***** Helpers *****

# functions to print out using colors
end="\033[0m"
black="\033[0;30m"
blackb="\033[1;30m"
white="\033[0;37m"
whiteb="\033[1;37m"
red="\033[0;31m"
redb="\033[1;31m"
green="\033[0;32m"
greenb="\033[1;32m"
yellow="\033[0;33m"
yellowb="\033[1;33m"
blue="\033[0;34m"
blueb="\033[1;34m"
purple="\033[0;35m"
purpleb="\033[1;35m"
lightblue="\033[0;36m"
lightblueb="\033[1;36m"

function black { echo -e "${black}${1}${end}"; }
function blackb { echo -e "${blackb}${1}${end}"; }
function white { echo -e "${white}${1}${end}"; }
function whiteb { echo -e "${whiteb}${1}${end}"; }
function red { echo -e "${red}${1}${end}"; }
function redb { echo -e "${redb}${1}${end}"; }
function green { echo -e "${green}${1}${end}"; }
function greenb { echo -e "${greenb}${1}${end}"; }
function yellow { echo -e "${yellow}${1}${end}"; }
function yellowb { echo -e "${yellowb}${1}${end}"; }
function blue { echo -e "${blue}${1}${end}"; }
function blueb { echo -e "${blueb}${1}${end}"; }
function purple { echo -e "${purple}${1}${end}"; }
function purpleb { echo -e "${purpleb}${1}${end}"; }
function lightblue { echo -e "${lightblue}${1}${end}"; }
function lightblueb { echo -e "${lightblueb}${1}${end}"; }

# Functions to fetch network data

# Mac OSX Specific Functions
function default_gateway_darwin { netstat -nr | grep -m 1 default | awk '{print $2}'; }
function wifi_signal_darwin { cat $OUT_DIR/current_wifi | grep agrCtlRSSI | awk '{print $2}'; }
function wifi_noise_darwin { cat $OUT_DIR/current_wifi | grep agrCtlNoise | awk '{print $2}'; }
function wifi_phy_rate_darwin { cat $OUT_DIR/current_wifi | grep lastTxRate | awk '{print $2}'; }
function record_current_wifi_details_darwin { /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I > $OUT_DIR/current_wifi; }

# Mac OSX and Linux Functions
function record_ip_details { ifconfig > $OUT_DIR/ifconfig; } 
function ping_host { ping -c 60 $1 > $OUT_DIR/$2_ping & }

# ***** Run analysis *****

OS=`uname -s | awk '{ print tolower($0) }'`
OUT_DIR=netreport
mkdir -p $OUT_DIR

echo "Recopilando informacion de la red..."

record_ip_details
record_current_wifi_details_$OS

signal=$(wifi_signal_$OS)
noise=$(wifi_noise_$OS)
datarate=$(wifi_phy_rate_$OS)
snr=$(expr $signal - $noise)
signal_status=[$(green "BUENA" )] && [[ $signal -lt -67 ]] && signal_status="[BAJA]"
snr_status=[$(green "BUENO")] && [[ $snr -lt 25 ]] && snr_status="[BAJO]"

echo $(lightblueb "Resultado:")
echo $(whiteb "Señal:") $signal dBm $signal_status
echo $(whiteb "Interferencia:") $noise dBm
echo $(whiteb "SNR:") $snr dBm $snr_status
echo $(whiteb "Data rate PHY:") $datarate Mbps
echo $(whiteb "Velocidad máxima TCP/IP:") $(expr $datarate / 2) Mbps

echo "Midiendo latencia durante 1 minuto..."

default_gateway=$(default_gateway_$OS)

ping_host 8.8.8.8 dns
ping_host $default_gateway gateway
wait

echo "Completado"

gateway_ping_summary=`tail -n 1 $OUT_DIR/gateway_ping | sed 's/.*= \(.*\) ms/\1/'`
gateway_avg_ping=`echo $gateway_ping_summary | awk -F / '{ print $2 }'`
gateway_max_ping=`echo $gateway_ping_summary | awk -F / '{ print $3 }'`

dns_ping_summary=`tail -n 1 $OUT_DIR/dns_ping | sed 's/.*= \(.*\) ms/\1/'`
dns_avg_ping=`echo $dns_ping_summary | awk -F / '{ print $2 }'`
dns_max_ping=`echo $dns_ping_summary | awk -F / '{ print $3 }'`

echo $(lightblueb "Resultado:")
echo $(whiteb "Default Gateway ($default_gateway):")
echo $(whiteb "Avg:") $gateway_avg_ping ms
echo $(whiteb "Max:") $gateway_max_ping ms
echo $(whiteb "Google DNS (8.8.8.8):")
echo $(whiteb "Avg:") $dns_avg_ping ms
echo $(whiteb "Max:") $dns_max_ping ms
