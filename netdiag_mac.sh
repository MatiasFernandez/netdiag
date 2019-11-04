#!/bin/bash

# ***** Helpers *****

# Colors
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

function black {
  echo -e "${black}${1}${end}"
}

function blackb {
  echo -e "${blackb}${1}${end}"
}

function white {
  echo -e "${white}${1}${end}"
}

function whiteb {
  echo -e "${whiteb}${1}${end}"
}

function red {
  echo -e "${red}${1}${end}"
}

function redb {
  echo -e "${redb}${1}${end}"
}

function green {
  echo -e "${green}${1}${end}"
}

function greenb {
  echo -e "${greenb}${1}${end}"
}

function yellow {
  echo -e "${yellow}${1}${end}"
}

function yellowb {
  echo -e "${yellowb}${1}${end}"
}

function blue {
  echo -e "${blue}${1}${end}"
}

function blueb {
  echo -e "${blueb}${1}${end}"
}

function purple {
  echo -e "${purple}${1}${end}"
}

function purpleb {
  echo -e "${purpleb}${1}${end}"
}

function lightblue {
  echo -e "${lightblue}${1}${end}"
}

function lightblueb {
  echo -e "${lightblueb}${1}${end}"
}

# ***** Run analysis *****

OUT=netreport
mkdir -p $OUT

echo "Recopilando informacion de la red..."
ifconfig > $OUT/ifconfig
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I > $OUT/current_wifi

SIGNAL=`cat $OUT/current_wifi | grep agrCtlRSSI | awk '{print $2}'`
NOISE=`cat netreport/current_wifi | grep agrCtlNoise | awk '{print $2}'`
DATARATE=`cat netreport/current_wifi | grep lastTxRate | awk '{print $2}'`
SNR=$(expr $SIGNAL - $NOISE)
SIGNAL_STATUS=[$(green "OK" )] && [[ $SIGNAL -lt -67 ]] && SIGNAL_STATUS="[BAJA]"
SNR_STATUS=[$(green "OK")] && [[ $SNR -lt 25 ]] && SNR_STATUS="[BAJO]"

echo $(lightblueb "Resultado:")
echo $(whiteb "Señal:") $SIGNAL dBm $SIGNAL_STATUS
echo $(whiteb "Interferencia:") $NOISE dBm
echo $(whiteb "SNR:") $SNR dBm $SNR_STATUS
echo $(whiteb "Data rate PHY:") $DATARATE Mbps
echo $(whiteb "Velocidad máxima TCP/IP:") $(expr $DATARATE / 2) Mbps

echo "Midiendo latencia durante 1 minuto..."
DEFAULT_GATEWAY=`netstat -nr | grep -m 1 default | awk '{print $2}'`

ping -c 60 8.8.8.8 > $OUT/dns_ping &
ping -c 60 $DEFAULT_GATEWAY > $OUT/gateway_ping &
wait
echo "Completado"
