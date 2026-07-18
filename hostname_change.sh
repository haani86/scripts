#!/bin/bash

# Path to your icon (Setup Assistant icon from CoreTypes.bundle)
ICON="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns"

# Loop until we get a non‑empty, valid hostname
while true; do
  # 1) Prompt for hostname
  NEW_HOSTNAME=$(osascript <<EOD
tell application "System Events"
    activate
    display dialog "Enter the new hostname for this Mac:\n(letters, numbers, hyphens only)" \
        default answer "" \
        with title "⚠️ Set Computer Hostname" \
        buttons {"OK"} default button "OK" \
        with icon (POSIX file "$ICON" as alias)
    text returned of result
end tell
EOD
)
  # Handle Cancel
  if [ $? -ne 0 ]; then
    echo "User cancelled hostname entry."
    exit 1
  fi

  # Trim whitespace
  NEW_HOSTNAME=$(echo "$NEW_HOSTNAME" | awk '{$1=$1};1')

  # 2) Empty‑string check
  if [[ -z "$NEW_HOSTNAME" ]]; then
    osascript <<EOD
tell application "System Events"
    activate
    display dialog "Hostname cannot be empty. Please try again." \
        with title "⚠️ Invalid Hostname" \
        buttons {"OK"} default button "OK" \
        with icon (POSIX file "$ICON" as alias)
end tell
EOD
    continue
  fi

  # 3) Character validation
  if [[ ! "$NEW_HOSTNAME" =~ ^[A-Za-z0-9-]+$ ]]; then
    osascript <<EOD
tell application "System Events"
    activate
    display dialog "Invalid hostname. Only letters, numbers, and hyphens are allowed." \
        with title "⚠️ Invalid Hostname" \
        buttons {"OK"} default button "OK" \
        with icon (POSIX file "$ICON" as alias)
end tell
EOD
    continue
  fi

  # Valid input
  break
done

# Build a clean LocalHostName (Bonjour/mDNS)
LOCAL_HOSTNAME=$(echo "$NEW_HOSTNAME" | sed -E 's/[^A-Za-z0-9]//g')

# Apply the names
scutil --set ComputerName  "$NEW_HOSTNAME"
scutil --set HostName      "$NEW_HOSTNAME"
scutil --set LocalHostName "$LOCAL_HOSTNAME"

# Final confirmation
osascript <<EOD
tell application "System Events"
    activate
    display dialog "Hostname set to: $NEW_HOSTNAME" \
        with title "Hostname Set" \
        buttons {"OK"} default button "OK" \
        with icon (POSIX file "$ICON" as alias)
end tell
EOD

exit 0