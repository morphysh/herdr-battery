#!/bin/sh
# Battery report popup for the herdr-battery plugin (pane entrypoint "details").
# Runs inside a real terminal pane, so ANSI styling is fine here.

bat=""
for d in /sys/class/power_supply/BAT*; do
    [ -e "$d/capacity" ] && bat="$d" && break
done

printf '\033[1;4mBattery\033[0m\n\n'
if [ -z "$bat" ]; then
    printf 'No battery found on this machine.\n\n\033[2m(press q to close)\033[0m'
    while IFS= read -r k; do break; done
    exit 0
fi

read_val() { cat "$bat/$1" 2>/dev/null; }

capacity=$(read_val capacity)
status=$(read_val status)
charge_now=$(read_val charge_now)
charge_full=$(read_val charge_full)
charge_design=$(read_val charge_full_design)
cycles=$(read_val cycle_count)
voltage_now=$(read_val voltage_now)
current_now=$(read_val current_now)

# Health: full charge vs design capacity (uAh).
if [ -n "$charge_full" ] && [ -n "$charge_design" ] && [ "$charge_design" -gt 0 ] 2>/dev/null; then
    health=$(awk -v f="$charge_full" -v d="$charge_design" 'BEGIN { printf "%.1f", f * 100 / d }')
else
    health="?"
fi

# Instantaneous power draw (uV * uA -> W).
power=""
if [ -n "$voltage_now" ] && [ -n "$current_now" ]; then
    power=$(awk -v v="$voltage_now" -v i="$current_now" 'BEGIN { printf "%.2f", v * i / 1e12 }')
fi

# Estimated time to full / empty (hours), from uAh and uA.
eta=""
if [ -n "$current_now" ] && [ "$current_now" -gt 0 ] 2>/dev/null && [ -n "$charge_now" ] && [ -n "$charge_full" ]; then
    eta=$(awk -v r="$charge_full" -v n="$charge_now" -v i="$current_now" 'BEGIN {
        h = (r - n) / i; m = int((h - int(h)) * 60); printf "~%dh%02dm to full", int(h), m }')
elif [ -n "$current_now" ] && [ "$current_now" -lt 0 ] 2>/dev/null && [ -n "$charge_now" ]; then
    eta=$(awk -v n="$charge_now" -v i="$current_now" 'BEGIN {
        h = n / (-i); m = int((h - int(h)) * 60); printf "~%dh%02dm left", int(h), m }')
fi

[ -n "$cycles" ] || cycles="?"
row() { printf '  \033[2m%-12s\033[0m %s\n' "$1" "$2"; }

row "Charge"   "${capacity:-?}% (${status:-unknown})"
row "Health"   "${health}% of design"
row "Cycles"   "$cycles"
[ -n "$power" ] && row "Power"    "${power} W"
[ -n "$eta" ] && row "Estimate" "$eta"
row "Source"   "$bat"

printf '\n\033[2m(press q to close)\033[0m'
while IFS= read -r k; do break; done
