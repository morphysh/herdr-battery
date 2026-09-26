#!/bin/sh
# Clickable battery icon for herdr panes (OSC 8 hyperlink).
#
# Inside a herdr pane, Ctrl+click on the emitted icon is routed to the
# rock.battery "details" action by the plugin's [[link_handlers]] entry,
# opening the full system report popup. Plain click does nothing useful
# (custom scheme), so the icon is inert outside herdr.

link="herdr-battery://status"

if [ -r /sys/class/power_supply/BAT1/capacity ]; then
    cap=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null)
    st=$(cat /sys/class/power_supply/BAT1/status 2>/dev/null)
    case "$st" in
        Charging)      icon="⚡" ;;
        Discharging)   icon="🔋" ;;
        "Not charging") icon="🔌" ;;
        *)             icon="🔋" ;;
    esac
    text="${icon}${cap}%"
else
    text="🔋"
fi

printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$link" "$text"
