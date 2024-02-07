#!/usr/bin/env bash

APP_NAME=$(basename "$0")

log () {
    if [ ! -z "${1}" ]; then
        LOG_LEVEL="${2:-DEBUG}"
        INGEST_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "${INGEST_DATE} ${LOG_LEVEL} (${APP_NAME}): $1"
        if [ ! -z "${KASM_API_JWT}" ]  && [ ! -z "${KASM_API_HOST}" ]  && [ ! -z "${KASM_API_PORT}" ]; then
            http_proxy="" https_proxy="" curl https://${KASM_API_HOST}:${KASM_API_PORT}/api/kasm_session_log?token=${KASM_API_JWT} --max-time 1 -X POST -H 'Content-Type: application/json' -d '[{ "host": "'"${KASM_ID}"'", "application": "Session", "ingest_date": "'"${INGEST_DATE}"'", "message": "'"$1"'", "levelname": "'"${LOG_LEVEL}"'", "process": "'"${APP_NAME}"'", "kasm_user_name": "'"${KASM_USER_NAME}"'", "kasm_id": "'"${KASM_ID}"'" }]' -k -s
        fi
    fi
}

cleanup() {
    log "The kasm_pre_shutdown_user script was interrupted." "ERROR"
}

trap cleanup 2 6 9 15

log "Executing kasm_pre_shutdown_user.sh" "INFO"

PAUSE_ON_EXIT="false"
if [ -z ${KASM_PROFILE_CHUNK_SIZE} ]; then
  KASM_PROFILE_CHUNK_SIZE=100000
fi

if [ -f /usr/bin/kasm-profile-sync ]; then
	kasm_profile_sync_found=1
fi

for x in {1..10}
do

    if [[ $(timeout 1 wmctrl -l | awk '{$3=""; $2=""; $1=""; print $0}' | grep -i chrome) ]]
    then
        PAUSE_ON_EXIT="true"
        echo "Closing Chrome Windows Attempt ($x)..."
        timeout 1 wmctrl -c chrome
        sleep .5
    fi

done

for x in {1..10}
do

    if [[ $(timeout 1 wmctrl -l | awk '{$3=""; $2=""; $1=""; print $0}' | grep -i firefox) ]]
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
            log 'Profile size limit exceeded.' 'WARNING'
            exit 0
        fi
    fi
    
    if [ -z "$kasm_profile_sync_found" ]; then
        log "Profile sync not available"
    else
        log "Packing and uploading user profile to object storage."
        PROFILE_SYNC_STATUS=1
        if [[ $DEBUG == true ]]; then
            OUTPUT=$(http_proxy="" https_proxy="" /usr/bin/kasm-profile-sync --upload /home/kasm-user --insecure --filter "${KASM_PROFILE_FILTER}" --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT} --verbose 2>&1 )
            PROFILE_SYNC_STATUS=$?
        else
            OUTPUT=$(http_proxy="" https_proxy="" /usr/bin/kasm-profile-sync --upload /home/kasm-user --insecure --filter "${KASM_PROFILE_FILTER}" --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT} 2>&1 )
            PROFILE_SYNC_STATUS=$?
        fi

        while IFS= read -r line; do
            log "$line"
        done <<< "$OUTPUT"

        if [ $PROFILE_SYNC_STATUS -ne 0 ]; then
            log "Failed to syncronize user profile, see debug logs." "ERROR"
        else
            log "Profile upload complete."
        fi        
    fi
fi

echo "Done"