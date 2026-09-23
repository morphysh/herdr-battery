#!/bin/sh
# Memory usage for the herdr tab bar: 🧠62%
#
# Used% = (MemTotal - MemAvailable) / MemTotal from /proc/meminfo.
# Linux only; empty exit clears the tab bar entry elsewhere.

[ -r /proc/meminfo ] || exit 0

awk '/^MemTotal:/      { t = $2 }
     /^MemAvailable:/  { a = $2 }
     END {
         if (t <= 0) exit
         used = t - a
         if (used < 0) used = 0
         printf "🧠%d%%", 100 * used / t
     }' /proc/meminfo
