#!/bin/bash

OUT=netreport
mkdir -p $OUT

echo "Recopilando informacion de la red..."
ifconfig > $OUT/ifconfig
/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I > $OUT/current_wifi

SIGNAL=`cat $OUT/current_wifi | grep agrCtlRSSI | awk '{print $2}'`
NOISE=`cat netreport/current_wifi | grep agrCtlNoise | awk '{print $2}'`
DATARATE=`cat netreport/current_wifi | grep lastTxRate | awk '{print $2}'`
SNR=$(expr $SIGNAL - $NOISE)
SIGNAL_STATUS="[OK]" && [[ $SIGNAL -lt -67 ]] && SIGNAL_STATUS="[BAJA]"
SNR_STATUS="[OK]" && [[ $SNR -lt 25 ]] && SNR_STATUS="[BAJO]"

echo "Resultado:"
echo Señal: $SIGNAL dBm $SIGNAL_STATUS
echo Interferencia: $NOISE dBm
echo SNR: $SNR dBm $SNR_STATUS
echo Data rate PHY: $DATARATE Mbps
echo Velocidad máxima TCP/IP: $(expr $DATARATE / 2) Mbps

echo "Midiendo latencia durante 1 minuto..."
DEFAULT_GATEWAY=`netstat -nr | grep -m 1 default | awk '{print $2}'`

ping -c 60 8.8.8.8 > $OUT/dns_ping &
ping -c 60 $DEFAULT_GATEWAY > $OUT/gateway_ping &
wait
echo "Completado"
