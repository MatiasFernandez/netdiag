#!/bin/bash

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

# Mac OSX Specific Network Functions
function default_gateway_darwin { netstat -nr | grep -m 1 default | awk '{print $2}'; }
function wifi_signal_darwin { cat $OUT_DIR/wifi_info | grep agrCtlRSSI | awk '{print $2}'; }
function wifi_noise_darwin { cat $OUT_DIR/wifi_info | grep agrCtlNoise | awk '{print $2}'; }
function tx_phy_data_rate_darwin { cat $OUT_DIR/wifi_info | grep lastTxRate | awk '{print $2}'; }
function rx_phy_data_rate_darwin { echo; } # OSX does not report Rx data rate
function record_wifi_info_darwin { /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I > $OUT_DIR/wifi_info; }
function record_ip_info_darwin { ifconfig > $OUT_DIR/ip_info; } 

# Linux Specific Network Functions
function interface_name { echo /sys/class/net/*/wireless | awk -F'/' '{ print $5 }'; }
function default_gateway_linux { ip route show | head -n 1 | sed 's/default via \(.*\) dev.*/\1/'; }
function wifi_signal_linux { grep "signal" $OUT_DIR/wifi_info | awk '{ print $2 }'; }
function wifi_noise_linux { echo; } # I need to investigate if noise is reported in Linux
function tx_phy_data_rate_linux { grep "tx bitrate" $OUT_DIR/wifi_info | awk '{ print $3 }'; }
function rx_phy_data_rate_linux { grep "rx bitrate" $OUT_DIR/wifi_info | awk '{ print $3 }'; }
function record_wifi_info_linux { iw dev $(interface_name) link > $OUT_DIR/wifi_info; }
function record_ip_info_linux { ip a > $OUT_DIR/ip_info; } 

# Mac OSX and Linux Network Functions
function ping_host { ping -c 60 $1 > $OUT_DIR/$2_ping & }

# Percentile calculation
function p50 { cat $1 | grep time | sed 's/.*time=\(.*\) ms/\1/' | sort -n | awk '{all[NR] = $0} END{print all[int(NR*0.50)]}'; }
function p90 { cat $1 | grep time | sed 's/.*time=\(.*\) ms/\1/' | sort -n | awk '{all[NR] = $0} END{print all[int(NR*0.90)]}'; }
function p95 { cat $1 | grep time | sed 's/.*time=\(.*\) ms/\1/' | sort -n | awk '{all[NR] = $0} END{print all[int(NR*0.95)]}'; }

function format_as_bad_when_low { result=$(red BAJ$4) && [[ $1 -gt $2 ]] && result=$(yellow MEDI$4) && [[ $1 -gt $3 ]] && result=$(green ALT$4); echo $result; }
function format_as_bad_when_high { result=$(green BAJ$4) && [[ $1 -gt $2 ]] && result=$(yellow MEDI$4) && [[ $1 -gt $3 ]] && result=$(red ALT$4); echo $result; }

# ***** Analysis Run *****

OS=`uname -s | awk '{ print tolower($0) }'`
LOW_SIGNAL=-65
MED_SIGNAL=-60
LOW_SNR=25
MED_SNR=30
LOW_NOISE=-90
MED_NOISE=-87

OUT_DIR=netreport
mkdir -p $OUT_DIR

echo -e "$(lightblue "Recopilando informacion de la red...")\n"

record_ip_info_$OS
record_wifi_info_$OS

signal=$(wifi_signal_$OS)
tx_phy_rate=$(tx_phy_data_rate_$OS)
tx_tcp_rate=$(echo "$tx_phy_rate / 2" | bc)
rx_data_rate=$(rx_phy_data_rate_$OS)
noise=$(wifi_noise_$OS)

echo $(whiteb "Señal:") $signal dBm [$(format_as_bad_when_low $signal $LOW_SIGNAL $MED_SIGNAL A)]

if [[ -n $noise ]]
then
  snr=$(echo "$signal - $noise" | bc)
  echo $(whiteb "Interferencia:") $noise dBm [$(format_as_bad_when_high $noise $LOW_NOISE $MED_NOISE A)]
  echo $(whiteb "SNR:") $snr dBm [$(format_as_bad_when_low $snr $LOW_SNR $MED_SNR A)]
fi

echo $(whiteb "Tx PHY Data rate:") $tx_phy_rate Mbps
echo $(whiteb "Tx máximo ideal (TCP/IP):") $tx_tcp_rate Mbps

if [[ -n $rx_phy_rate ]]
then
  rx_tcp_rate=$(echo "$rx_phy_rate / 2" | bc)
  echo $(whiteb "Rx PHY Data rate:") $rx_phy_rate Mbps
  echo $(whiteb "Rx máximo ideal (TCP/IP):") $rx_tcp_rate Mbps
fi

echo -e "\n$(lightblue "Midiendo latencia durante 1 minuto...")\n"

default_gateway=$(default_gateway_$OS)

ping_host 8.8.8.8 dns
ping_host $default_gateway gateway
wait

gateway_ping_summary=`tail -n 1 $OUT_DIR/gateway_ping | sed 's/.*= \(.*\) ms/\1/'`
gateway_ping_packet_loss=`cat $OUT_DIR/gateway_ping | grep "packet loss" | sed 's/.* \([0-9]*\.*[0-9]*\)%.*/\1/'`
gateway_avg_ping=`echo $gateway_ping_summary | awk -F / '{ print $2 }'`
gateway_max_ping=`echo $gateway_ping_summary | awk -F / '{ print $3 }'`

dns_ping_summary=`tail -n 1 $OUT_DIR/dns_ping | sed 's/.*= \(.*\) ms/\1/'`
dns_ping_packet_loss=`cat $OUT_DIR/dns_ping | grep "packet loss" | sed 's/.* \([0-9]*\.*[0-9]*\)%.*/\1/'`
dns_avg_ping=`echo $dns_ping_summary | awk -F / '{ print $2 }'`
dns_max_ping=`echo $dns_ping_summary | awk -F / '{ print $3 }'`

echo $(whiteb "Latencia a Default Gateway ($default_gateway):")
echo $(whiteb "Avg:") $gateway_avg_ping ms
echo $(whiteb "P50:") $(p50 $OUT_DIR/gateway_ping) ms
echo $(whiteb "P90:") $(p90 $OUT_DIR/gateway_ping) ms
echo $(whiteb "P95:") $(p95 $OUT_DIR/gateway_ping) ms
echo $(whiteb "Max:") $gateway_max_ping ms
echo $(whiteb "Packet Loss:") $gateway_ping_packet_loss %

echo -e "\n$(whiteb "Latencia a Google DNS (8.8.8.8):")"
echo $(whiteb "Avg:") $dns_avg_ping ms
echo $(whiteb "P50:") $(p50 $OUT_DIR/dns_ping) ms
echo $(whiteb "P90:") $(p90 $OUT_DIR/dns_ping) ms
echo $(whiteb "P95:") $(p95 $OUT_DIR/dns_ping) ms
echo $(whiteb "Max:") $dns_max_ping ms
echo $(whiteb "Packet Loss:") $dns_ping_packet_loss %

echo -e "\n$(greenb "Recomendaciones:")"
echo "* Con tu conexión Wi-Fi actual no podes alcanzar mas de $(whiteb "$tx_tcp_rate Mbps") de data rate. Asegurate que este numero sea mayor que el servicio de internet que tenes contratado"
[[ $signal -lt $LOW_SIGNAL ]] && echo "* $(red "Tu señal es muy baja"). Proba acercarte al access point o reconectar tu Wi-Fi para ver si mejora"
