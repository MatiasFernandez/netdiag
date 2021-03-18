timestamped () {
  while read command
  do 
    echo "$(date +"%Y-%m-%dT%H:%M:%S%z") $command"
  done
}

repeat () {
  for (( i=1; i<=$2 ; i++ ))
  do
    echo `$1`
    sleep $3
  done
}
