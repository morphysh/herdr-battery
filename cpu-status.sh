#!/bin/sh
# CPU usage for the herdr tab bar: 📈12%
#
# Busy% across all cores, sampled over a 0.5s window from /proc/stat.
# Linux only; empty exit clears the tab bar entry elsewhere.

[ -r /proc/stat ] || exit 0

sample() {
    awk 'NR==1 {
        busy = $2 + $3 + $4 + $7 + $8 + $9   # user nice system irq softirq steal
        total = busy + $5 + $6               # + idle iowait
        print busy, total
    }' /proc/stat
}

a=$(sample) || exit 0
sleep 0.5
b=$(sample) || exit 0

awk -v a="$a" -v b="$b" 'BEGIN {
    split(a, x, " "); split(b, y, " ")
    dt = y[2] - x[2]; db = y[1] - x[1]
    if (dt <= 0) { print "📈--"; exit }
    pct = 100 * db / dt
    if (pct > 100) pct = 100
    printf "📈%d%%", pct
}'
