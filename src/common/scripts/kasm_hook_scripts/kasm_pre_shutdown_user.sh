#!/usr/bin/env bash
set -e
echo "Executing kasm_pre_shutdown_user.sh"

PAUSE_ON_EXIT="false"
if [ -z ${KASM_PROFILE_CHUNK_SIZE} ]; then
  KASM_PROFILE_CHUNK_SIZE=100000
fi

if [ -f /usr/bin/kasm-profile-sync ]; then
	kasm_profile_sync_found=1
fi

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

if [ ! -z "$KASM_PROFILE_LDR" ]; then
    CURRENT_SIZE=$(du -s $HOME | grep -Po '^\d+')
    if [ -z ${KASM_PROFILE_FILTER} ]; then
        KASM_PROFILE_FILTER=".vnc,.cache,Downloads,Uploads,.config/*/Singleton*"
    fi

    if [ ! -z "$KASM_PROFILE_SIZE_LIMIT" ]; then
        SIZE_LIMIT_MB=$(echo "$KASM_PROFILE_SIZE_LIMIT / 1000" | bc)
        if [[ $CURRENT_SIZE -gt KASM_PROFILE_SIZE_LIMIT ]]; then
            http_proxy="" https_proxy="" curl -k "https://${KASM_API_HOST}:${KASM_API_PORT}/api/set_kasm_session_status?token=${KASM_API_JWT}" -H 'Content-Type: application/json' -d '{"destroyed": true}'
            echo 'Profile size limit exceeded.'
            exit 0
        fi
    fi
    
    if [ -z "$kasm_profile_sync_found" ]; then
        echo >&2 "Profile sync not available"
    else
        echo "Packing and uploading user profile to object storage."
        if [[ $DEBUG == true ]]; then
            http_proxy="" https_proxy="" /usr/bin/kasm-profile-sync --upload /home/kasm-user --insecure --filter "${KASM_PROFILE_FILTER}" --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT} --verbose
        else
            http_proxy="" https_proxy="" /usr/bin/kasm-profile-sync --upload /home/kasm-user --insecure --filter "${KASM_PROFILE_FILTER}" --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT}
        fi
        echo "Profile upload complete."
    fi
fi

echo "Done"
