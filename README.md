# herdr-plugin-battery

Laptop battery status for [herdr](https://herdr.dev):

- **Tab bar, real time** — a one-line status with state icons:
  `⚡87%` charging (plugged in), `🔋87%` on battery, `🔌100%` plugged in but
  held/full, `🔋15%!` low battery (below 20% on battery).
  Rendered by herdr's `command` status widget; resolves on the herdr *server*,
  so `herdr --remote` shows the remote machine's battery.
- **Details popup** — charge, health vs design capacity, cycle count, power draw,
  and time-to-full/empty estimate. `prefix+shift+b` (configurable).

Linux only (reads `/sys/class/power_supply/BAT*`). No dependencies beyond POSIX `sh`.

## Install (local development)

```sh
herdr plugin link ~/Projects/herdr-battery
```

## Wire up the tab bar entry

`~/.config/herdr/config.toml`:

```toml
[ui]
tab_bar_right = [
  { type = "zoom" },
  { type = "hostname" },
  { type = "command", command = "~/Projects/herdr-battery/battery-status.sh", interval_seconds = 10, timeout_seconds = 2 },
]

# Optional keybinding for the popup
[[keys.command]]
key = "prefix+shift+b"
type = "plugin_action"
command = "rock.battery.details"
description = "Battery details"
```

Then `herdr server reload-config`.

If you move this directory, update the `command` path in `config.toml` (linked
plugin roots are not stable paths for third-party installs).

## Files

| File                | Purpose                                              |
| ------------------- | ---------------------------------------------------- |
| `herdr-plugin.toml` | Plugin manifest (action + popup pane)                |
| `battery-status.sh` | Tab bar one-liner (used by the `command` widget)      |
| `battery-details.sh`| Popup report (pane entrypoint `details`)              |
| `open-details.sh`   | Action entrypoint: opens the popup via `HERDR_BIN_PATH` |

## Publish

Push to a public GitHub repo, add the topic `herdr-plugin`, and it gets indexed
by the [marketplace](https://herdr.dev/plugins) within ~30 minutes. Others install with:

```sh
herdr plugin install <owner>/herdr-plugin-battery
```

and point `tab_bar_right` at the installed path (or keep their own copy of
`battery-status.sh` under `~/.config/herdr/`).
