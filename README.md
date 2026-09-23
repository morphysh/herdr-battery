# herdr-battery

System status for [herdr](https://herdr.dev): battery, CPU, and memory.

- **Tab bar, real time** — separate widgets, each with its own refresh interval:
  - `⚡87%` charging (plugged in) / `🔋87%` on battery / `🔌100%` plugged in but held/full,
    `🔋15%!` low battery (below 20% on battery)
  - `📈12%` CPU busy across all cores (0.5s sampling window)
  - `🐏62%` memory in use
  - Rendered by herdr's `command` status widgets; they resolve on the herdr *server*,
    so `herdr --remote` shows the remote machine's metrics.
- **System report popup** — `prefix+shift+b` (configurable): battery health, cycles,
  power draw and time-to-full/empty, CPU usage/load/temperature, RAM+swap, disk
  usage, uptime.

Linux only (reads `/sys/class/power_supply` and `/proc`). No dependencies beyond
POSIX `sh` + `awk` + `df`.

## Install (local development)

```sh
herdr plugin link ~/Projects/herdr-battery
```

## Wire up the tab bar entries

`~/.config/herdr/config.toml`:

```toml
[ui]
tab_bar_right = [
  { type = "zoom" },
  { type = "hostname" },
  { type = "command", command = "~/Projects/herdr-battery/cpu-status.sh", interval_seconds = 5, timeout_seconds = 2 },
  { type = "command", command = "~/Projects/herdr-battery/mem-status.sh", interval_seconds = 15, timeout_seconds = 2 },
  { type = "command", command = "~/Projects/herdr-battery/battery-status.sh", interval_seconds = 15, timeout_seconds = 2 },
]
tab_bar_right_separator = " · "

# Optional keybinding for the popup
[[keys.command]]
key = "prefix+shift+b"
type = "plugin_action"
command = "rock.battery.details"
description = "System report"
```

Then `herdr server reload-config`.

If you move this directory, update the `command` paths in `config.toml` (linked
plugin roots are not stable paths for third-party installs).

## Files

| File                | Purpose                                               |
| ------------------- | ----------------------------------------------------- |
| `herdr-plugin.toml` | Plugin manifest (popup action + pane)                 |
| `battery-status.sh` | Tab bar battery line (`command` widget)               |
| `cpu-status.sh`     | Tab bar CPU busy% (`command` widget)                  |
| `mem-status.sh`     | Tab bar memory used% (`command` widget)               |
| `sys-details.sh`    | Full system report popup (pane entrypoint `details`)  |
| `open-details.sh`   | Action entrypoint: opens the popup via `HERDR_BIN_PATH` |

## Tuning

- Low battery threshold: `LOW_PERCENT` at the top of `battery-status.sh`.
- CPU sampling window: the `sleep 0.5` in `cpu-status.sh` (keep well under the
  widget's `timeout_seconds`).

## Changelog

- **0.2.0** — CPU and memory tab bar widgets; popup becomes a full system
  report (CPU/load/temp, RAM/swap, disk, uptime).
- **0.1.0** — battery tab bar widget + details popup.

## Publish

Push to a public GitHub repo, add the topic `herdr-plugin`, and it gets indexed
by the [marketplace](https://herdr.dev/plugins) within ~30 minutes. Others install with:

```sh
herdr plugin install morphysh/herdr-battery
```

and point `tab_bar_right` at the installed path (or keep their own copy of the
status scripts under `~/.config/herdr/`).
