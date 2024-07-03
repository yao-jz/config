#!/bin/bash

WINDOW_NAME="Visual Studio Code"
LAST_WINDOW_FILE="/tmp/last_vscode_window_id"

# get the focused window ID
FOCUSED_WINDOW_ID_DEC=$(xdotool getwindowfocus)

# get all app window IDs (in hex)
WINDOW_IDS_HEX=$(wmctrl -l | grep "$WINDOW_NAME" | awk '{print $1}')

# check if there are any app windows
if [ -z "$WINDOW_IDS_HEX" ]; then
  setsid code &>/dev/null &
  exit 0
fi

# convert hex to dec
WINDOW_IDS_DEC=()
for WINDOW_ID_HEX in $WINDOW_IDS_HEX; do
  WINDOW_IDS_DEC+=($(printf "%d\n" "$WINDOW_ID_HEX"))
done

# check if the focused window is a app window
IS_FOCUSED=false
for WINDOW_ID_DEC in "${WINDOW_IDS_DEC[@]}"; do
  if [ "$FOCUSED_WINDOW_ID_DEC" == "$WINDOW_ID_DEC" ]; then
    IS_FOCUSED=true
    break
  fi
done

if [ "$IS_FOCUSED" == true ]; then
  echo "$FOCUSED_WINDOW_ID_DEC" > "$LAST_WINDOW_FILE"
  # notify-send "app is focused, stored window ID in $LAST_WINDOW_FILE" $FOCUSED_WINDOW_ID_DEC
  # hide all app windows
  for WINDOW_ID_HEX in $WINDOW_IDS_HEX; do
    xdotool windowminimize $WINDOW_ID_HEX
  done
else
  if [ -f "$LAST_WINDOW_FILE" ]; then
    LAST_WINDOW_ID_HEX=$(printf "0x0%x\n" "$(cat "$LAST_WINDOW_FILE")")
    # notify-send "app is not focused, trying to restore last window" $LAST_WINDOW_ID_HEX
    # check if the last window is still open
    if wmctrl -l | grep -q "$LAST_WINDOW_ID_HEX"; then
      wmctrl -ir "$LAST_WINDOW_ID_HEX" -b remove,hidden
      xdotool windowactivate "$LAST_WINDOW_ID_HEX"
      exit 0
    fi
  fi
  # show and focus the first app window
  # notify-send "app is not focused"
  wmctrl -ir "$WINDOW_IDS_HEX" -b remove,hidden
  xdotool windowactivate "$WINDOW_IDS_HEX"
fi
