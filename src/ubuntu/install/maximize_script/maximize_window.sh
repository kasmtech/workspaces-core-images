# MAXIMIZE and MAXIMIZE_NAME are exported by the calling script
# This script will check against the container OS to do the right thing.

# Array of codenames that support maximus
MAXIMUS_CODENAMES=("bionic")
# Array of codenames that support wmctrl
WMCTRL_CODENAMES=("focal")

maximize_window(){
    set +e
    if [[ ${MAXIMIZE} == 'true' ]] ; then
        if [[ ${MAXIMUS_CODENAMES[*]} =~  $(lsb_release -cs) ]] ; then
            # only start maximus if it isn't already running
            if ! pgrep -x maximus > /dev/null
            then
                maximus &
            fi
        fi
        if [[ ${WMCTRL_CODENAMES[*]} =~  $(lsb_release -cs) ]] ; then
            while true; do
                end=$((SECONDS+60))
                while [ $SECONDS -lt $end ]; do
                    windows=$(wmctrl -l)
                    if [[ "$windows" =~ "${MAXIMIZE_NAME}" ]];
                    then
                        echo "Found ${MAXIMIZE_NAME}, maximizing"
                        wmctrl -r "${MAXIMIZE_NAME}" -b add,maximized_vert,maximized_horz
                        break;
                    fi
                    sleep 1
                done
                sleep 10
            done
        fi
    fi
    set -e
}

maximize_window