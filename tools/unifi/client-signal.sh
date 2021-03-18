# Example usage: cat 'client-signal.sh' | ssh 'sh -s MAC_ADDRESS NUM_CHECKS'
i=1; while [ $i -le $2 ]; do echo `stainfo -1 | grep $1 | while read command; do echo "$(date +"%Y-%m-%dT%H:%M:%S%z") $command"; done | awk '{gsub(/\s+/,",") ; print $0}'`; sleep 1; i=$((i+1)); done
