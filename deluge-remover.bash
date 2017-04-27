#!/bin/bash

# configuration
# -------------
## who and how long?
DELUGE_REMOVER_TRACKER=${DELUGE_REMOVER_TRACKER:="example.org"}
DELUGE_REMOVER_MAX_DAYS=${DELUGE_REMOVER_MAX_DAYS:=7}

## define credentials in "/var/lib/deluge/.config/deluge/auth" file
DELUGE_REMOVER_USERNAME=${DELUGE_REMOVER_USERNAME:="deluger"}
DELUGE_REMOVER_PASSWORD=${DELUGE_REMOVER_PASSWORD:="p@55W0rd"}

## enable remote access if not localhost
DELUGE_REMOVER_SERVER=${DELUGE_REMOVER_SERVER:="127.0.0.1"}
DELUGE_REMOVER_PORT=${DELUGE_REMOVER_PORT:="58846"}
DELUGE_REMOVER_WORKING_DIR=${DELUGE_REMOVER_WORKING_DIR:="$( dirname "${BASH_SOURCE[0]}" )"}


# execution
# ---------
## trump local environment variables
cd "$DELUGE_REMOVER_WORKING_DIR"
if [ -f .env ]; then
  source .env
fi

## get state
state=$( deluge-console "connect $DELUGE_REMOVER_SERVER:$DELUGE_REMOVER_PORT $DELUGE_REMOVER_USERNAME $DELUGE_REMOVER_PASSWORD; info" )

## get line numbers for select tracker into an array
tracker_lines=( $( echo -e "$state" | grep -n "Tracker status: $DELUGE_REMOVER_TRACKER" | cut -f1 -d: ) )

## subtract line numbers to get date lines
for tracker_line in ${tracker_lines[@]}; do

  time_line=$((tracker_line - 1))
  ## extract day number from line
  days=$( ( awk -v n=$time_line 'NR == n' <( echo -e "$state" ) ) | cut -f2 -d: | cut -f2 -d' ' )

  ## get IDs over max seed time
  if [ $days -gt $DELUGE_REMOVER_MAX_DAYS ]; then
    id_line=$((tracker_line - 5))
    ## extract id
    id=$( ( awk -v n=$id_line 'NR == n' <( echo -e "$state" ) ) | cut -f2 -d' ' )
    ## remove
    deluge-console "connect $DELUGE_REMOVER_SERVER:$DELUGE_REMOVER_PORT $DELUGE_REMOVER_USERNAME $DELUGE_REMOVER_PASSWORD; rm $id --remove_data"
  fi

done
