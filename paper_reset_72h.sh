#!/bin/bash
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
RESET_FILE="$SCRIPT_DIR/reset_at.txt"
SERVER_DIR="$(realpath "$SCRIPT_DIR/..")"
BACKUP_DIR="$SERVER_DIR/backup"
JAR_FILE="$SERVER_DIR/paper.jar"
MOTD_FILE="$SERVER_DIR/server.properties"
SESSION_NAME="minecraft"

SECONDS_PER_HOURS=$((60 * 60))
SECONDS_PER_DAY=$((24 * $SECONDS_PER_HOURS))
SECONDS_PER_72_HOURS=$((72 * $SECONDS_PER_HOURS))

set_next_reset_time() {
	local now epoch_today_4am next_reset
	now=$(date +%s)
	epoch_today_4am=$(date -d "04:00" +%s)
	next_reset=$epoch_today_4am
	while [ $(($next_reset - $now)) -le $SECONDS_PER_72_HOURS ]; do
		next_reset=$(($next_reset + $SECONDS_PER_DAY))
	done
	next_reset=$(($next_reset - $SECONDS_PER_DAY))
	echo $next_reset >"$RESET_FILE"
}

is_server_running() {
	screen -list | grep -q "$SESSION_NAME"
}

update_motd() {
	local reset_epoch reset_str
	reset_epoch=$(cat "$RESET_FILE")
	reset_str=$(date -d "@$reset_epoch" +"%Y-%m-%d %H:%M")
	sed -i "/^motd=/c\motd=§c72-hour reset §8| §eNext reset: $reset_str (JST)" "$MOTD_FILE"
}

send_notice() {
	local remaining_minutes="$1"
	local hours=$((remaining_minutes / 60))
	local minutes=$((remaining_minutes % 60))
	local now_str=$(date +"%Y-%m-%d %H:%M")
	local message="§eServer resets in §c${hours}h §6${minutes}m§f."
	screen -S "$SESSION_NAME" -X stuff "say ${message}\r"
}

stop_server() {
	if is_server_running; then
		screen -S "$SESSION_NAME" -X stuff "stop\r"
		sleep 20
	fi
}

delete_session() {
	stop_server
	if is_server_running; then
		screen -S "$SESSION_NAME" -X quit
		sleep 20
	fi
}

start_server() {
	update_motd
	delete_session
	(
		cd "$SERVER_DIR" || exit 1
		screen -dmS "$SESSION_NAME" java -Xms512M -Xmx1G -jar "$JAR_FILE" --nogui
	)
}

clean_and_backup_server() {
	delete_session
	mkdir -p "$BACKUP_DIR"
	rm -rf "$BACKUP_DIR"/*
	local timestamp=$(date +"%Y%m%d_%H%M")
	local backup_path="$BACKUP_DIR/world-$timestamp"
	mv "$SERVER_DIR/world" "$backup_path"

	if [ -d "$SERVER_DIR/world_nether/DIM-1" ]; then
		mv "$SERVER_DIR/world_nether/DIM-1" "$backup_path/DIM-1"
	fi
	if [ -d "$SERVER_DIR/world_the_end/DIM1" ]; then
		mv "$SERVER_DIR/world_the_end/DIM1" "$backup_path/DIM1"
	fi

	(
		cd "$BACKUP_DIR" || exit 1
		zip -qr "world-latest.zip" "world-$timestamp"
		rm -rf "world-$timestamp"
	)

	rm -rf "$SERVER_DIR/world_nether"
	rm -rf "$SERVER_DIR/world_the_end"
	rm -rf "$RESET_FILE"
}

now=$(date +%s)
[ ! -f "$RESET_FILE" ] && set_next_reset_time
reset_at=$(cat "$RESET_FILE")
if ! is_server_running; then
	start_server
	exit 0
fi
seconds_left=$(($reset_at - $now))
minutes_left=$((($seconds_left + 30) / 60))
if [ $minutes_left -le 0 ]; then
	send_notice 0
	sleep 30
	clean_and_backup_server
	set_next_reset_time
	start_server
else
	send_notice $minutes_left
fi
exit 0
