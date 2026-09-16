#!/bin/sh
# One-line laptop battery status for the herdr tab bar (command widget).
#
# Output:  ⚡87%    charging (plugged in, filling)
#          🔋87%    discharging (running on battery)
#          🔌100%   plugged in, not charging (held/full)
#          🔋15%!   low battery (below LOW_PERCENT while on battery)
#
# Renders on the Herdr server, so remote attaches show the server's battery.
# Empty output clears the tab bar entry (desktops without a battery).

LOW_PERCENT=20

bat=""
for d in /sys/class/power_supply/BAT*; do
    [ -e "$d/capacity" ] && bat="$d" && break
done
[ -n "$bat" ] || exit 0

cap=$(cat "$bat/capacity" 2>/dev/null) || exit 0
status=$(cat "$bat/status" 2>/dev/null)

case "$status" in
    Charging)      icon="⚡" ;;
    Discharging)   icon="🔋" ;;
    "Not charging") icon="🔌" ;;
    *)             icon="🔋" ;;
esac

line="${icon}${cap}%"
if [ "$status" = "Discharging" ] && [ "$cap" -lt "$LOW_PERCENT" ]; then
    line="${line}!"
fi
printf '%s' "$line"
