#!/bin/bash
### every exit != 0 fails the script
set -e

no_proxy="localhost,127.0.0.1"

if [ -f /usr/bin/kasm-profile-sync ]; then
	kasm_profile_sync_found=1
fi

# Set lang values
if [ "${LC_ALL}" != "en_US.UTF-8" ]; then
  export LANG=${LC_ALL}
  export LANGUAGE=${LC_ALL}
fi

# dict to store processes
declare -A KASM_PROCS

# switch passwords to local variables
tmpval=$VNC_VIEW_ONLY_PW
unset VNC_VIEW_ONLY_PW
VNC_VIEW_ONLY_PW=$tmpval
tmpval=$VNC_PW
unset VNC_PW
VNC_PW=$tmpval

BUILD_ARCH=$(uname -p)
if [ -z ${KASM_PROFILE_CHUNK_SIZE} ]; then
  KASM_PROFILE_CHUNK_SIZE=100000
fi
if [ -z ${DRINODE+x} ]; then
  DRINODE="/dev/dri/renderD128"
fi
KASMNVC_HW3D=''
if [ ! -z ${HW3D+x} ]; then
  KASMVNC_HW3D="-hw3d"
fi
STARTUP_COMPLETE=0

######## FUNCTION DECLARATIONS ##########

## print out help
function help (){
	echo "
		USAGE:

		OPTIONS:
		-w, --wait      (default) keeps the UI and the vncserver up until SIGINT or SIGTERM will received
		-s, --skip      skip the vnc startup and just execute the assigned command.
		                example: docker run kasmweb/core --skip bash
		-d, --debug     enables more detailed startup output
		                e.g. 'docker run kasmweb/core --debug bash'
		-h, --help      print out this help

		Fore more information see: https://github.com/ConSol/docker-headless-vnc-container
		"
}

trap cleanup SIGINT SIGTERM SIGQUIT SIGHUP ERR

function pull_profile (){
	if [ ! -z "$KASM_PROFILE_LDR" ]; then
		if [ -z "$kasm_profile_sync_found" ]; then
			echo >&2 "Profile sync not available"
			sleep 3
			http_proxy="" https_proxy="" curl -k "https://${KASM_API_HOST}:${KASM_API_PORT}/api/set_kasm_session_status?token=${KASM_API_JWT}" -H 'Content-Type: application/json' -d '{"status": "running"}'
			return
		fi

		echo "Downloading and unpacking user profile from object storage."
		set +e
		http_proxy="" https_proxy="" /usr/bin/kasm-profile-sync --download /home/kasm-user --insecure --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT}
		PROCESS_SYNC_EXIT_CODE=$?
		set -e
		if (( PROCESS_SYNC_EXIT_CODE > 1 )); then
			echo "Profile-sync failed with a non-recoverable error. See server side logs for more details."
			exit 1
		fi
		echo "Profile load complete."
		# Update the status of the container to running
		sleep 3
		http_proxy="" https_proxy="" curl -k "https://${KASM_API_HOST}:${KASM_API_PORT}/api/set_kasm_session_status?token=${KASM_API_JWT}" -H 'Content-Type: application/json' -d '{"status": "running"}'

	fi
}

function  push_profile(){
	if [ ! -z "$KASM_PROFILE_LDR" ]; then
		if [ -z "$kasm_profile_sync_found" ]; then
			echo >&2 "Profile sync not available"
			return
		fi

		echo "Packing and uploading user profile to object storage."
		/usr/bin/kasm-profile-sync --upload /home/kasm-user --insecure --remote ${KASM_API_HOST} --port ${KASM_API_PORT} -c ${KASM_PROFILE_CHUNK_SIZE} --token ${KASM_API_JWT}
		echo "Profile upload complete."
	fi
}

function profile_size_check(){
	if [ ! -z "$KASM_PROFILE_SIZE_LIMIT" ]
	then
		SIZE_CHECK_FAILED=false
		while true
		do
			sleep 60
			CURRENT_SIZE=$(du -s $HOME | grep -Po '^\d+')
			SIZE_LIMIT_MB=$(echo "$KASM_PROFILE_SIZE_LIMIT / 1000" | bc)
			if [[ $CURRENT_SIZE -gt KASM_PROFILE_SIZE_LIMIT ]]
			then
				notify-send "Profile Size Exceeds Limit" "Your home profile has exceeded the size limit of ${SIZE_LIMIT_MB}MB. Changes on your desktop will not be saved between sessions until you reduce the size of your profile." -i /usr/share/icons/ubuntu-mono-dark/apps/22/dropboxstatus-x.svg -t 57000
				SIZE_CHECK_FAILED=true
			else
				if [ "$SIZE_CHECK_FAILED" = true ] ; then
					SIZE_CHECK_FAILED=false
					notify-send "Profile Size" "Your home profile size is now under the limit and will be saved when your session is terminated." -i /usr/share/icons/ubuntu-mono-dark/apps/22/dropboxstatus-logo.svg -t 57000
				fi
			fi
		done
	fi
}

## correct forwarding of shutdown signal
function cleanup () {
    kill -s SIGTERM $!
    exit 0
}

function start_kasmvnc (){
	if [[ $DEBUG == true ]]; then
	  echo -e "\n------------------ Start KasmVNC Server ------------------------"
	fi

	DISPLAY_NUM=$(echo $DISPLAY | grep -Po ':\d+')

	if [[ $STARTUP_COMPLETE == 0 ]]; then
	    vncserver -kill $DISPLAY &> $STARTUPDIR/vnc_startup.log \
	    || rm -rfv /tmp/.X*-lock /tmp/.X11-unix &> $STARTUPDIR/vnc_startup.log \
	    || echo "no locks present"
	fi

	rm -rf $HOME/.vnc/*.pid
	echo "exit 0" > $HOME/.vnc/xstartup
	chmod +x $HOME/.vnc/xstartup

	VNCOPTIONS="$VNCOPTIONS -select-de manual"
	if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] && [[ -f /lib/aarch64-linux-gnu/libgcc_s.so.1 ]] ; then
		LD_PRELOAD=/lib/aarch64-linux-gnu/libgcc_s.so.1 vncserver $DISPLAY $KASMVNC_HW3D -drinode $DRINODE -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -websocketPort $NO_VNC_PORT -httpd ${KASM_VNC_PATH}/www -sslOnly -FrameRate=$MAX_FRAME_RATE -interface 0.0.0.0 -BlacklistThreshold=0 -FreeKeyMappings $VNCOPTIONS $KASM_SVC_SEND_CUT_TEXT $KASM_SVC_ACCEPT_CUT_TEXT
	else
		vncserver $DISPLAY $KASMVNC_HW3D -drinode $DRINODE -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -websocketPort $NO_VNC_PORT -httpd ${KASM_VNC_PATH}/www -sslOnly -FrameRate=$MAX_FRAME_RATE -interface 0.0.0.0 -BlacklistThreshold=0 -FreeKeyMappings $VNCOPTIONS $KASM_SVC_SEND_CUT_TEXT $KASM_SVC_ACCEPT_CUT_TEXT
	fi

	KASM_PROCS['kasmvnc']=$(cat $HOME/.vnc/*${DISPLAY_NUM}.pid)

	#Disable X11 Screensaver
	if [ "${DISTRO}" != "alpine" ]; then
		echo "Disabling X Screensaver Functionality"
		xset -dpms
		xset s off
		xset q
	else
		echo "Disabling of X Screensaver Functionality for $DISTRO is not required."
	fi

	if [[ $DEBUG == true ]]; then
	  echo -e "\n------------------ Started Websockify  ----------------------------"
	  echo "Websockify PID: ${KASM_PROCS['kasmvnc']}";
	fi
}

function start_window_manager (){
	echo -e "\n------------------ Xfce4 window manager startup------------------"

	if [ "${START_XFCE4}" == "1" ] ; then
		if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "${KASM_EGL_CARD}" ] && [ ! -z "${KASM_RENDERD}" ] && [ -O "${KASM_RENDERD}" ] && [ -O "${KASM_EGL_CARD}" ] ; then
		echo "Starting XFCE with VirtualGL using EGL device ${KASM_EGL_CARD}"
			DISPLAY=:1 /opt/VirtualGL/bin/vglrun -d "${KASM_EGL_CARD}" /usr/bin/startxfce4 --replace &
		else
			echo "Starting XFCE"
			if [ -f '/usr/bin/zypper' ]; then
				DISPLAY=:1 /usr/bin/dbus-launch /usr/bin/startxfce4 --replace &
			else
				/usr/bin/startxfce4 --replace &
			fi
		fi
		KASM_PROCS['window_manager']=$!
	else
		echo "Skipping XFCE Startup"
	fi
}

function start_audio_out_websocket (){
	if [[ ${KASM_SVC_AUDIO:-1} == 1 ]]; then
		echo 'Starting audio websocket server'
		$STARTUPDIR/jsmpeg/kasm_audio_out-linux kasmaudio 8081 4901 ${HOME}/.vnc/self.pem ${HOME}/.vnc/self.pem "kasm_user:$VNC_PW"  &

		KASM_PROCS['kasm_audio_out_websocket']=$!

		if [[ $DEBUG == true ]]; then
		  echo -e "\n------------------ Started Audio Out Websocket  ----------------------------"
		  echo "Kasm Audio Out Websocket PID: ${KASM_PROCS['kasm_audio_out_websocket']}";
		fi
	fi
}

function start_audio_out (){
	if [[ ${KASM_SVC_AUDIO:-1} == 1 ]]; then
		echo 'Starting audio server'

        if [ "${START_PULSEAUDIO:-0}" == "1" ] ;
        then
            echo "Starting Pulse"
            HOME=/var/run/pulse pulseaudio --start
        fi

		if [[ $DEBUG == true ]]; then
			echo 'Starting audio service in debug mode'
			HOME=/var/run/pulse no_proxy=127.0.0.1 ffmpeg -f pulse -fragment_size ${PULSEAUDIO_FRAGMENT_SIZE:-2000} -ar 44100 -i default -f mpegts -correct_ts_overflow 0 -codec:a mp2 -b:a 128k -ac 1 -muxdelay 0.001 http://127.0.0.1:8081/kasmaudio &
			KASM_PROCS['kasm_audio_out']=$!
		else
			echo 'Starting audio service'
			HOME=/var/run/pulse no_proxy=127.0.0.1 ffmpeg -v verbose -f pulse -fragment_size ${PULSEAUDIO_FRAGMENT_SIZE:-2000} -ar 44100 -i default -f mpegts -correct_ts_overflow 0 -codec:a mp2 -b:a 128k -ac 1 -muxdelay 0.001 http://127.0.0.1:8081/kasmaudio > /dev/null 2>&1 &
			KASM_PROCS['kasm_audio_out']=$!
			echo -e "\n------------------ Started Audio Out  ----------------------------"
			echo "Kasm Audio Out PID: ${KASM_PROCS['kasm_audio_out']}";
		fi
	fi
}

function start_audio_in (){
	if [[ ${KASM_SVC_AUDIO_INPUT:-1} == 1 ]]; then
		echo 'Starting audio input server'
		$STARTUPDIR/audio_input/kasm_audio_input_server --ssl --auth-token "kasm_user:$VNC_PW" --cert ${HOME}/.vnc/self.pem --certkey ${HOME}/.vnc/self.pem &

		KASM_PROCS['kasm_audio_in']=$!

		if [[ $DEBUG == true ]]; then
			echo -e "\n------------------ Started Audio Out Websocket  ----------------------------"
			echo "Kasm Audio In PID: ${KASM_PROCS['kasm_audio_in']}";
		fi
	fi
}

function start_upload (){
	if [[ ${KASM_SVC_UPLOADS:-1} == 1 ]]; then
		echo 'Starting upload server'
		$STARTUPDIR/upload_server/kasm_upload_server --ssl --auth-token "kasm_user:$VNC_PW" &

		KASM_PROCS['upload_server']=$!

		if [[ $DEBUG == true ]]; then
			echo -e "\n------------------ Started Upload Server  ----------------------------"
			echo "Upload Server PID: ${KASM_PROCS['upload_server']}";
		fi
	fi
}

function start_gamepad (){
	if [[ ${KASM_SVC_GAMEPAD:-1} == 1 ]]; then
		echo 'Starting gamepad server'
		$STARTUPDIR/gamepad/kasm_gamepad_server --ssl --auth-token "kasm_user:$VNC_PW" --cert ${HOME}/.vnc/self.pem --certkey ${HOME}/.vnc/self.pem &

		KASM_PROCS['kasm_gamepad']=$!

		if [[ $DEBUG == true ]]; then
			echo -e "\n------------------ Started Gamepad Websocket  ----------------------------"
			echo "Kasm Gamepad PID: ${KASM_PROCS['kasm_gamepad']}";
		fi
	fi
}

function start_webcam (){
	if [[ ${KASM_SVC_WEBCAM:-1} == 1 ]] && [[ -e /dev/video0 ]]; then
		echo 'Starting webcam server'
                if [[ $DEBUG == true ]]; then
			$STARTUPDIR/webcam/kasm_webcam_server --debug --port 4905 --ssl --cert ${HOME}/.vnc/self.pem --certkey ${HOME}/.vnc/self.pem &
		else
			$STARTUPDIR/webcam/kasm_webcam_server --port 4905 --ssl --cert ${HOME}/.vnc/self.pem --certkey ${HOME}/.vnc/self.pem &
		fi

		KASM_PROCS['kasm_webcam']=$!

		if [[ $DEBUG == true ]]; then
			echo -e "\n------------------ Started Webcam Websocket  ----------------------------"
			echo "Kasm Webcam PID: ${KASM_PROCS['kasm_webcam']}";
		fi
	fi
}

function custom_startup (){
	custom_startup_script=/dockerstartup/custom_startup.sh
	if [ -f "$custom_startup_script" ]; then
		if [ ! -x "$custom_startup_script" ]; then
			echo "${custom_startup_script}: not executable, exiting"
			exit 1
		fi

		"$custom_startup_script" &
		KASM_PROCS['custom_startup']=$!
	fi
}

############ END FUNCTION DECLARATIONS ###########

if [[ $1 =~ -h|--help ]]; then
    help
    exit 0
fi

# Syncronize user-space loaded persistent profiles
pull_profile

# should also source $STARTUPDIR/generate_container_user
if [ -f $HOME/.bashrc ]; then
    source $HOME/.bashrc
fi

if [[ ${KASM_DEBUG:-0} == 1 ]]; then
    echo -e "\n\n------------------ DEBUG KASM STARTUP -----------------"
    export DEBUG=true
    set -x
fi

## resolve_vnc_connection
VNC_IP=$(hostname -i)
if [[ $DEBUG == true ]]; then
    echo "IP Address used for external bind: $VNC_IP"
fi

# Create cert for KasmVNC
mkdir -p ${HOME}/.vnc
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ${HOME}/.vnc/self.pem -out ${HOME}/.vnc/self.pem -subj "/C=US/ST=VA/L=None/O=None/OU=DoFu/CN=kasm/emailAddress=none@none.none"

# first entry is control, second is view (if only one is valid for both)
mkdir -p "$HOME/.vnc"
PASSWD_PATH="$HOME/.kasmpasswd"
if [[ -f $PASSWD_PATH ]]; then
    echo -e "\n---------  purging existing VNC password settings  ---------"
    rm -f $PASSWD_PATH
fi
VNC_PW_HASH=$(python3 -c "import crypt; print(crypt.crypt('${VNC_PW}', '\$5\$kasm\$'));")
VNC_VIEW_PW_HASH=$(python3 -c "import crypt; print(crypt.crypt('${VNC_VIEW_ONLY_PW}', '\$5\$kasm\$'));")
echo "kasm_user:${VNC_PW_HASH}:ow" > $PASSWD_PATH
echo "kasm_viewer:${VNC_VIEW_PW_HASH}:" >> $PASSWD_PATH
chmod 600 $PASSWD_PATH


# start processes
start_kasmvnc
start_window_manager
start_audio_out_websocket
start_audio_out
start_audio_in
start_upload
start_gamepad
profile_size_check &
start_webcam

STARTUP_COMPLETE=1


## log connect options
echo -e "\n\n------------------ KasmVNC environment started ------------------"

# tail vncserver logs
tail -f $HOME/.vnc/*$DISPLAY.log &

KASMIP=$(hostname -i)
echo "Kasm User ${KASM_USER}(${KASM_USER_ID}) started container id ${HOSTNAME} with local IP address ${KASMIP}"

# start custom startup script
custom_startup

# Monitor Kasm Services
sleep 3
while :
do
	for process in "${!KASM_PROCS[@]}"; do
		if ! kill -0 "${KASM_PROCS[$process]}" ; then

			# If DLP Policy is set to fail secure, default is to be resilient
			if [[ ${DLP_PROCESS_FAIL_SECURE:-0} == 1 ]]; then
				exit 1
			fi

			case $process in
				kasmvnc)
					if [ "$KASMVNC_AUTO_RECOVER" = true ] ; then
						echo "KasmVNC crashed, restarting"
						start_kasmvnc
					else
						echo "KasmVNC crashed, exiting container"
						exit 1
					fi
					;;
				window_manager)
					echo "Window manager crashed, restarting"
					start_window_manager
					;;
				kasm_audio_out_websocket)
					echo "Restarting Audio Out Websocket Service"
					start_audio_out_websocket
					;;
				kasm_audio_out)
					echo "Restarting Audio Out Service"
					start_audio_out
					;;
				kasm_audio_in)
					echo "Audio In Service Failed"
					# TODO: Needs work in python project to support auto restart
					# start_audio_in
					;;
				upload_server)
					echo "Restarting Upload Service"
					# TODO: This will only work if both processes are killed, requires more work
					start_upload
					;;
				kasm_gamepad)
					echo "Gamepad Service Failed"
					# TODO: Needs work in python project to support auto restart
					# start_gamepad
					;;
				kasm_webcam)
					echo "Webcam Service Failed"
					# TODO: Needs work in python project to support auto restart
					start_webcam
					;;
				custom_script)
					echo "The custom startup script exited."
					# custom startup scripts track the target process on their own, they should not exit
					custom_startup
					;;
				*)
					echo "Unknown Service: $process"
					;;
			esac
		fi
	done
	sleep 3
done


echo "Exiting Kasm container"
