#!/usr/bin/env bash
set -x

source $STARTUPDIR/generate_container_user

LOCK_FILE=/tmp/.kasm_profile_sync.lock
KASM_BACKGROUND_SYNC_TIMER="${KASM_BACKGROUND_SYNC_TIMER:-30}"
KASM_BACKGROUND_SYNC_ERROR_BACKOFF="${KASM_BACKGROUND_SYNC_ERROR_BACKOFF:-60}"
KASM_BACKGROUND_SYNC_CONN_TIMEOUT="${KASM_BACKGROUND_SYNC_CONN_TIMEOUT:-10}"
KASM_BACKGROUND_SYNC_TIMEOUT="${KASM_BACKGROUND_SYNC_TIMEOUT:-120}"

title="Kasm Background Profile Synchronization"
error=false
sync_error=false


function unison_sync_stop {
    echo "Checking For Stop Signal"
    msg="Stop Background Sync Message Received. Exiting"
    test -f /tmp/unison-stop && notify-send -u critical -t 0 -i /usr/share/icons/ubuntu-mono-dark/apps/22/gtg-panel.svg "$title : $(date)" "$msg" && rm /tmp/unison-stop && exit 0  || return 0
}

function unison_sync {
    echo "Executing Unison Sync"
    touch $LOCK_FILE
    OUT=$(timeout --signal=KILL $KASM_BACKGROUND_SYNC_TIMEOUT unison kasm-profile -silent)
    #FIXME -can we catch the timeout error code
    case $? in
        0)
            msg="Kasm Profile Sync Successful"
            echo $msg
            if [ "$error" = true ] ; then
                notify-send -u critical -t 0 -i /usr/share/icons/ubuntu-mono-dark/apps/22/gtg-panel.svg "$title : $(date)" "$msg"
            fi
            error=false

            ;;
        1)
            echo  "all file transfers were successful; some files were skipped. $OUT"
            ;;
        2)
            echo "non-fatal failures during file transfer. $OUT"
            ;;
        3)
            msg="Fatal error occurred during profile sync. If the problem persists please contact an Administrator. $OUT"
            echo $msg
            if [ "$error" = false ] ; then
                notify-send -u critical -t 0 -i /usr/share/icons/ubuntu-mono-dark/apps/22/dropboxstatus-x.svg "$title : $(date)" "$msg"
            fi
            error=true
            ;;
        *)
            msg="unknown exit code occurred during profile sync. If the problem persists please contact an Administrator. $OUT"
            echo $msg
            if [ "$error" = false ] ; then
                notify-send -u critical -t 0 -i /usr/share/icons/ubuntu-mono-dark/apps/22/dropboxstatus-x.svg "$title : $(date)" "$msg"
            fi
            error=true
            ;;
    esac
    rm -f $LOCK_FILE
}

function test_fs_access {
    echo "Testing Sync Directory Acccess"
    OUT=$(timeout --signal=KILL $KASM_BACKGROUND_SYNC_CONN_TIMEOUT ls -d /kasm_profile_sync/)

    case $? in
        0)
            msg="Sync directory access successful"
            echo $msg
            unison_sync
            echo "Sleeping $KASM_BACKGROUND_SYNC_TIMER"
            sleep $KASM_BACKGROUND_SYNC_TIMER
            ;;

        *)

            msg="Unable to access profile sync directory. If the problem persists please contact an Administrator. $OUT"
            echo $msg
            if [ "$error" = false ] ; then
                notify-send -u critical -t 0 -i /usr/share/icons/ubuntu-mono-dark/apps/22/dropboxstatus-x.svg "$title : $(date)" "$msg"
            fi
            error=true
            echo "Sleeping $KASM_BACKGROUND_SYNC_ERROR_BACKOFF"
            sleep $KASM_BACKGROUND_SYNC_ERROR_BACKOFF
            ;;
    esac
}

while true
do
    unison_sync_stop
    test_fs_access
done