#!/bin/bash

# port, username, password
SERVER="localhost:9091 --auth fran:topo01"
MAX_RATIO=0

# use transmission-remote to get torrent list from transmission-remote list
TORRENTLIST=`transmission-remote $SERVER --list | sed -e '1d' -e '$d' | awk '{print $1}' | sed -e 's/[^0-9]*//g'`

# for each torrent in the list
for TORRENTID in $TORRENTLIST
do
    INFO=/tmp/$$.$TORRENTID.tmp
    transmission-remote $SERVER --torrent $TORRENTID --info > $INFO
    RATIO=`cat $INFO | grep 'Ratio:' | awk '{print $2}'`
    NAME=$(cat $INFO | sed -e 's/.*Name: \(.*\) Hash.*/\1/')
    #echo -e "Processing #$TORRENTID - $(cat $INFO | sed -e 's/.*Name: \(.*\) Hash.*/\1/')"
    echo "Processing #$TORRENTID -"
    
    # check if torrent download is completed
    DL_COMPLETED=`cat $INFO | grep "Done: 100%"`
    # check torrents current state is
    STATE_STOPPED=`cat $INFO | grep "State: Finished\|State: Idle"`

    # if the torrent is "Stopped", "Finished", or "Idle after downloading 100%"
    if [ "$DL_COMPLETED" ] && [ "$STATE_STOPPED" ] && [ $(echo "$RATIO >= $MAX_RATIO" | bc -l) -eq 1 ]; then
        echo "Torrent #$TORRENTID is completed. Removing torrent from list."
        transmission-remote $SERVER --torrent $TORRENTID --remove-and-delete
    else
        echo "Torrent #$TORRENTID is not completed. Ignoring."
    fi
done

#rm /tmp/$$.*.tmp
