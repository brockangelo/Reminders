#!/bin/bash
# This script creates a "cronjob" using MacOSX's preferred "launchd"
# Convert minutes to seconds, then create a one-time cron that
# simply calls up a sticky growlnotify with your reminder. 

GROWL=/usr/local/bin/growlnotify


### Cleanup Script Begins ###

if [[ $1 == "cleanup" ]]; then

	# get the list of plist files this user has created
	REMINDER_PLISTS=($(command ls ~/Library/LaunchAgents/com.approductive.remindersapp.*))
	
	# if there are plists, let's proceed to see if any are expired
	if [[ -n $REMINDER_PLISTS ]]; then

		echo "Cleaning up expired reminders..."
		
		# get list of active reminders
		ACTIVE_REMINDERS=($(launchctl list | grep com.approductive.remindersapp | awk '{print $3}'))
		
		# get total count of plist files to iterate	
		total_plists=${#REMINDER_PLISTS[*]}
		for (( i=0; i<=$(( $total_plists -1 )); i++ ))
		do
			# remove the .plist so it will match the launchctl output for comparison
			trimmed_plist=$(basename ${REMINDER_PLISTS[$i]} | sed 's#.plist##g')
			# compare existing plist file against active launchctl list
			is_active=$(echo "${ACTIVE_REMINDERS[@]}" | grep -o "$trimmed_plist")
			
			# if the plist is NOT active, remove the file
			if [[ -z $is_active ]]; then
				rm ${REMINDER_PLISTS[$i]}
			fi
		done
	fi

	# exit this script if there were plist files we cleaned up or not
	exit 0

fi

### Cleanup Script Ends ###


### Create Reminder Begins ###
# Format: remindme 1 the_reminder
# Format: remindme $1 $2

# Convert minutes to epoch
MINUTES=$1
TIMESTAMP=$(command date +%s)
TIMER=$(($1 * 60))

# Capture all remaining arguments as $REMINDER
shift
REMINDER=$*
echo "$MINUTES minute reminder:"
echo "$REMINDER"

# Insert the reminder as a plist file
cat > ~/Library/LaunchAgents/com.approductive.remindersapp.$TIMESTAMP.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.approductive.remindersapp.$TIMESTAMP</string>
	<key>ProgramArguments</key>
	<array>
		<string>$GROWL</string>
		<string>-s</string>
		<string>--image</string>
		<string>$HOME/Library/Application Support/Alfred/extensions/scripts/Reminders/reminders.png</string>
		<string>-m</string>
		<string>$REMINDER</string>
		<string>-t</string>
		<string>Reminders</string>
	</array>
	<key>StartInterval</key>
	<integer>$TIMER</integer>
	<key>RunAtLoad</key>
	<false/>
	<key>LaunchOnlyOnce</key>
	<true/>
</dict>
</plist>
EOF

# Set permissions, then load into launchd using launchctl
chmod 644 ~/Library/LaunchAgents/com.approductive.remindersapp.$TIMESTAMP.plist
launchctl load ~/Library/LaunchAgents/com.approductive.remindersapp.$TIMESTAMP.plist

### Create Reminder Ends ###
