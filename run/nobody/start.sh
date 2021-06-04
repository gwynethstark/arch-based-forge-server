#!/bin/bash

function accept_eula() {

	if [ ! -f '/config/forge/eula.txt' ]; then

		echo "[info] Starting Minecraft Java process to force creation of 'eula.txt'..."
		start_minecraft

		echo "[info] Waiting for Minecraft Java process to abort (expected, due to eula flag not set)..."
		while pgrep -fu "nobody" "java" > /dev/null; do
			sleep 0.1
		done
		echo "[info] Minecraft Java process ended (expected)"

	fi

	echo "[info] Checking EULA is set to 'true'..."
	cat '/config/forge/eula.txt' | grep -q 'eula=true'

	if [ "${?}" -eq 0 ]; then
		echo "[info] EULA set to 'true'"
	else
		echo "[info] EULA set to 'false', changing to 'true'..."
		sed -i -e 's~eula=false~eula=true~g' '/config/forge/eula.txt'
	fi

}

function start_minecraft() {

	# create logs sub folder to store screen output from console
	mkdir -p /config/forge/logs

	# run screen attached to minecraft (daemonized, non-blocking) to allow users to run commands in minecraft console
	echo "[info] Starting Minecraft Java process..."
	screen -L -Logfile '/config/forge/logs/screen.log' -d -S forged -m bash -c "sudo forged start"
	echo "[info] Minecraft Java process is running"
	if [[ ! -z "${STARTUP_CMD}" ]]; then
		startup_cmd
	fi

}

function startup_cmd() {

	# split comma separated string into array from STARTUP_CMD env variable
	IFS=',' read -ra startup_cmd_array <<< "${STARTUP_CMD}"

	# process startup cmds in the array
	for startup_cmd_item in "${startup_cmd_array[@]}"; do
		echo "[info] Executing startup Minecraft command '${startup_cmd_item}'"
		screen -S forged -p 0 -X stuff "${startup_cmd_item}^M"
	done

}

# if minecraft server.properties file doesnt exist then copy default to host config volume
if [ ! -f "/config/forge/server.properties" ]; then

	echo "[info] Minecraft server.properties file doesnt exist, copying default installation to '/config/minecraft/'..."

	mkdir -p /config/forge
	if [[ -d "/srv/forge" ]]; then
		cp -R /srv/forge/* /config/forge/ 2>/dev/null || true
	fi

else

	# rsync options defined as follows:-
	# -r = recursive copy to destination
	# -l = copy source symlinks as symlinks on destination
	# -t = keep source modification times for destination files/folders
	# -p = keep source permissions for destination files/folders
	echo "[info] Minecraft folder '/config/minecraft' already exists, rsyncing newer files..."
	rsync -rltp --exclude 'world' --exclude '/server.properties' --exclude '/*.json' /srv/forge/ /config/forge

fi

# accept eula
accept_eula

# start minecraft
start_minecraft
