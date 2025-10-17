#!/bin/bash
app_name="$1"

# Check if app is already running
if pgrep -x "$app_name" > /dev/null; then
    # App is running, just activate it
    osascript -e "tell application \"$app_name\" to activate"
else
    # App is not running, launch fresh without state restoration
    open -a "$app_name" --args --no-restore-state 2>/dev/null || \
    open -a "$app_name" --args -no-restore 2>/dev/null || \
    open -a "$app_name" 2>/dev/null
fi
