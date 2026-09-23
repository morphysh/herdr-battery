#!/bin/sh
# System report popup for the herdr-battery plugin (pane entrypoint "details").
# Battery + CPU + memory + disk + uptime. Runs in a real terminal pane,
# so ANSI styling is fine.

B() { printf '\033[1;4m%s\033[0m\n' "$1"; }
row() { printf '  \033[2m%-12s\033[0m %s\n' "$1" "$2"; }
dim() { printf '\033[2m%s\033[0m\n' "$1"; }

# ---------- Battery ----------
bat=""
for d in /sys/class/power_supply/BAT*; do
    [ -e "$d/capacity" ] && bat="$d" && break
done

B "Battery"
if [ -z "$bat" ]; then
    row "Charge" "no battery"
else
    rv() { cat "$bat/$1" 2>/dev/null; }
    capacity=$(rv capacity); status=$(rv status)
    charge_now=$(rv charge_now); charge_full=$(rv charge_full)
    charge_design=$(rv charge_full_design); cycles=$(rv cycle_count)
    voltage_now=$(rv voltage_now); current_now=$(rv current_now)

    [ -n "$cycles" ] || cycles="?"
    health="?"
    if [ -n "$charge_full" ] && [ -n "$charge_design" ] && [ "$charge_design" -gt 0 ] 2>/dev/null; then
        health=$(awk -v f="$charge_full" -v d="$charge_design" 'BEGIN { printf "%.1f", f * 100 / d }')
    fi
    power=""
    [ -n "$voltage_now" ] && [ -n "$current_now" ] && \
        power=$(awk -v v="$voltage_now" -v i="$current_now" 'BEGIN { printf "%.2f", v * i / 1e12 }')
    eta=""
    if [ "$current_now" -gt 0 ] 2>/dev/null && [ -n "$charge_full" ]; then
        eta=$(awk -v r="$charge_full" -v n="$charge_now" -v i="$current_now" 'BEGIN {
            h=(r-n)/i; printf "~%dh%02dm to full", int(h), int((h-int(h))*60) }')
    elif [ "$current_now" -lt 0 ] 2>/dev/null; then
        eta=$(awk -v n="$charge_now" -v i="$current_now" 'BEGIN {
            h=n/(-i); printf "~%dh%02dm left", int(h), int((h-int(h))*60) }')
    fi

    row "Charge"   "${capacity:-?}% (${status:-unknown})"
    row "Health"   "${health}% of design"
    row "Cycles"   "$cycles"
    [ -n "$power" ] && row "Power"    "${power} W"
    [ -n "$eta" ] && row "Estimate" "$eta"
fi

# ---------- CPU ----------
if [ -r /proc/stat ]; then
    B "CPU"
    cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo "?")
    load=$(cut -d' ' -f1-3 /proc/loadavg 2>/dev/null)
    cs() { awk 'NR==1{b=$2+$3+$4+$7+$8+$9; print b, b+$5+$6}' /proc/stat; }
    a=$(cs); sleep 0.5; c=$(cs)
    usage=$(awk -v a="$a" -v b="$c" 'BEGIN {
        split(a,x," "); split(b,y," "); dt=y[2]-x[2]; db=y[1]-x[1]
        if (dt<=0) { print "--"; exit } p=100*db/dt; if(p>100)p=100; printf "%d%%", p }')
    temp=""
    for tz in /sys/class/thermal/thermal_zone*/temp; do
        [ -r "$tz" ] || continue
        t=$(cat "$tz" 2>/dev/null) || continue
        case "$t" in ''|*[!0-9]*) continue ;; esac
        [ "$t" -gt 0 ] 2>/dev/null && temp=$(awk -v t="$t" 'BEGIN{printf "%.1f°C", t/1000}') && break
    done
    row "Usage"    "$usage across $cores cores"
    row "Load"     "${load:-?}"
    [ -n "$temp" ] && row "Temp" "$temp"
fi

# ---------- Memory ----------
if [ -r /proc/meminfo ]; then
    B "Memory"
    awk '/^MemTotal:/     { t=$2 }
         /^MemAvailable:/ { a=$2 }
         /^SwapTotal:/    { st=$2 }
         /^SwapFree:/     { sf=$2 }
         END {
             printf "  \033[2m%-12s\033[0m %.1f / %.1f GiB (available %.1f GiB)\n", "RAM", \
                 (t-a)/1048576, t/1048576, a/1048576
             if (st > 0) printf "  \033[2m%-12s\033[0m %.1f / %.1f GiB\n", "Swap", \
                 (st-sf)/1048576, st/1048576
         }' /proc/meminfo
fi

# ---------- Disk ----------
B "Disk"
df -h -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null | awk 'NR>1 && !seen[$1]++ {
    printf "  \033[2m%-12s\033[0m %s used of %s (%s free)\n", $6, $5, $2, $4
}' | head -6

# ---------- Uptime ----------
if [ -r /proc/uptime ]; then
    B "Uptime"
    up=$(awk '{printf "%d\n", $1}' /proc/uptime)
    row "Up" "$(awk -v s="$up" 'BEGIN{d=int(s/86400);h=int(s%86400/3600);m=int(s%3600/60);printf "%dd %dh %dm", d, h, m}')"
fi

printf '\n'
dim "(press q to close)"
while IFS= read -r k; do break; done
