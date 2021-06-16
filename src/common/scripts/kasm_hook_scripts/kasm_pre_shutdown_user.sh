#!/usr/bin/env bash
set -e
echo "Executing kasm_pre_shutdown_user.sh"
PAUSE_ON_EXIT="false"
for x in {1..10}
do

    if [[ $(wmctrl -l | awk '{$3=""; $2=""; $1=""; print $0}' | grep -i chrome) ]]
    then
        PAUSE_ON_EXIT="true"
        echo "Closing Chrome Windows Attempt ($x)..."
        timeout 1 wmctrl -c chrome
        sleep .5
    fi

done

for x in {1..10}
do

    if [[ $(wmctrl -l | awk '{$3=""; $2=""; $1=""; print $0}' | grep -i firefox) ]]
    then
        PAUSE_ON_EXIT="true"
        echo "Closing Firefox Windows Attempt ($x)..."
        timeout 1 wmctrl -c firefox
        sleep .5
    fi

done

if [ "${PAUSE_ON_EXIT}" == "true" ] ;
then
    echo "Sleeping..."
    sleep 1
fi

echo "Done"
