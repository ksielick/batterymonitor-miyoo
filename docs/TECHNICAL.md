# Battery Monitor: technical details

The [README](../README.md) is the player guide. This page keeps the details behind it: what each value means, how the PMIC behaves, the low-battery cut-off and the SD card, and how to build the app. Register-level notes and datasheet sources are in [AXP223_REGISTERS.md](AXP223_REGISTERS.md).

---

## Why the stock percentage jumps

On the Miyoo Mini Plus and Mini Flip the battery percentage comes from the X-Powers PMIC (AXP223, register-compatible with AXP221). Out of the box no battery capacity is set in it, so it estimates the level from the battery voltage (OCV). Under load the voltage sags, so the percentage:
- drops by 15-25 % when a demanding emulator starts (PS1, GBA...),
- can stay at 10 % or 4 % for up to 2 hours of play,
- jumps up or down after a wake from sleep.

The PMIC also has a hardware **Coulomb counter**: it measures the charge (mAh) flowing in and out of the battery. Once a capacity is set, the PMIC's percentage (REG B9H, the one Onion and RetroArch show everywhere, read through `axp_test`) follows that counter instead of the voltage. Measured on a Mini Plus: with a capacity set, B9H equals the counter's percentage to the point; without one it is voltage-based.

## The `[SELECT]` menu, value by value

| Value | Source | Meaning |
|:---|:---|:---|
| Battery Voltage | REG 78H/79H | Cell voltage, e.g. `4.19 V`. |
| Power Draw | REG 7AH-7DH | Current: negative while discharging (e.g. `-385 mA`), positive while charging. |
| Battery Level | REG B9H | The system percentage. `(est.)` when bit 7 says it is not correctly calculated yet. |
| Energy Remaining | REG E2H/E3H | Coulomb counter, 1.456 mAh per step. |
| Total Capacity | REG E0H/E1H | Capacity set by you or learned by the PMIC. |
| Voltage (OCV) | REG E4H | Voltage-based percentage. Follows the load. |
| Coulomb Ctr (CC) | REG E5H | Counter-based percentage. Bit 7 is clear while no capacity is set; the value then means nothing (it reads 100 %). |
| Fuel Gauge | REG B8H bit 7 | `Active` when the fuel gauge runs (factory default). |
| Cap. Learning | REG B8H bit 5 | Capacity correction switch. A persistent setting, not a one-shot cycle: it stays `Enabled` and keeps refining the capacity as the cell ages. Safe to leave on. |
| Correction | REG B8H bit 4 | `In progress` while the PMIC corrects the capacity. Observed on a Mini Plus (2026-11-09): it turns on when the charger is plugged in after a discharge to 1 %, with the console still running; no `Voff` power-off is needed. A charge started higher up leaves it `Idle`. |

The menu reads the PMIC once a second while it is open and not at all otherwise; the app uses under 0.1 % CPU when idle. Every write is read back, and the app reports when the PMIC rejected it.

## How the PMIC behaves (measured on a Mini Plus, 2026-11-08)

Starting from a factory-reset PMIC (battery unplugged for a minute: capacity and counter at 0, learning off):
1. **Saving a capacity** makes the PMIC fill the counter by itself, from the voltage. It needs no other step.
2. **Saved while charging**, the voltage reads high, so the counter starts high: it started at 2806 mAh of 2800, the rest of the charge pushed it to 3085 mAh, and **the PMIC never trims it back** to the capacity (CC just stays at 100 %).
3. **`Set current capacity to 100%`** at a real full charge (charging finished, 4.20 V, 0 mA) sets the counter to the capacity and changes nothing else.
4. **Enabling learning** sets REG B8H bit 5 and changes nothing else.

Hence the README's order: charge to 100 %, then set the capacity, then enable learning. Changing the capacity later also works; sync to 100 % at the next full charge.

Unplugging the battery resets only REG B8H (learning off) and REG E0H-E3H (capacity and counter). The other settings, `Voff` included, were at their defaults and stayed so.

## The full learning cycle in detail

1. Charge to 100 % (current near 0 mA).
2. Set the capacity, check that Energy Remaining is about Total Capacity (otherwise sync to 100 %).
3. Enable learning.
4. Set Onion's **Low batt.: Save and exit** to **Off** and **Sleep timer** to **Never**. Discharge down to 1 % (REG B9H), playing or idle.
   - Onion's software shutdown would stop the drain before the gauge reaches the bottom.
   - The sleep timer would autosave and power off first.
5. Plug in the charger at 1 % and charge straight to 100 % in one go. `Correction` switches to `In progress` when the charger goes in; at the end the PMIC writes the learned capacity into REG E0H/E1H (e.g. `3167 mAh` on a stock 3000 mAh cell).

Older versions of this guide ran the battery down to the PMIC's `Voff` cut-off (asleep, to protect the SD card). That also works but is not needed, and a hard power cut risks the card (see below).

Afterwards, set Onion's low-battery shutdown back on for everyday play.

## Low battery: Onion's shutdown and the PMIC cut-off

| | Onion low-battery shutdown | PMIC `Voff` cut-off |
|:---|:---|:---|
| Trigger | Battery percentage (Onion setting) | Voltage under load below `Voff` (default 2.9 V) |
| Saves game / state | Yes | **No.** All outputs are cut at once, with no documented delay |
| SD card | Clean | A write in progress can be interrupted, and other files can be hit too |
| Session log | Complete | Last minutes may be missing |

- **Is a deep discharge harmful?** No. 3.0-3.2 V resting is a safe floor for Li-ion cells. With `Voff` at 2.9 V the console shut down with the cell at 3.15 V resting (the load sags it by about 0.15-0.25 V).
- **Raising `Voff` to 3.0-3.1 V** leaves more reserve, but it is compared under load: a spike in a demanding game can then cut power while the cell still rests at about 3.2 V.
- `Voff` (REG 31H, 2.6-3.1 V in 0.1 V steps) is kept while the battery stays connected. Whether it survives a reboot is not confirmed yet.

### Hard power-off and the SD card

A `Voff` cut can damage **files nothing was writing at that moment**:
- **The FAT is shared.** One FAT sector holds the cluster chains of many files; an interrupted write to it (a log line, Onion's clock file, `system.json`) can cut the chains of neighbouring files.
- **SD cards write internally in large blocks** (often several MB). An interrupted program or erase can damage data written earlier into the same block.

*Observed on a Mini Plus (2026-11):* after several discharge-to-cut-off runs with the console in Battery Monitor at the cut, `retroarch.cfg` became unreadable. RetroArch silently regenerated it with its own defaults, not Onion's: no sound (`audio_driver = "audioio"`), *Fatal error* in the Game Switcher, dead MENU hotkeys, saves in the wrong folder. Windows' disk check found the lost pieces of `retroarch.cfg` and `system.json` in `FOUND.000`. Copying Onion's default `RetroArch/.retroarch/retroarch.cfg` back fixed it.

What helps: let the last stretch run asleep, check the card on a PC after any hard power-off, back the card up before deliberate discharge runs.

## Battery Health Test

About 45 s: an idle baseline with the screen dimmed, then both CPU cores at 100 % at 1200 MHz and 1600 MHz. The internal resistance comes from the voltage sag (dV/dI) and is rated EXCELLENT / GOOD / AGED / POOR. It needs at least 3.60 V on battery (no charger), stops below 3.50 V, with the charger or with `[B]`, and always restores the CPU clock, governor and brightness. Turn Wi-Fi off first for the cleanest reading.

## Graph and session statistics

- `LEFT` projects the remaining time by scaling your past discharge curve to the current session's load.
- Sleep is logged with its length and cost, e.g. `+3h10 SLEEP -12% (3.8%/H)`. Dates show only on models with a hardware clock (Mini Plus, Mini Flip).
- `AVG` / `MIN` / `BEST` count **finished** sessions only, i.e. sessions that end with the charger plugged in. A running session, even a record one, appears in `BEST` after you plug in.
- Durations come from Onion's `batmon` log, written when the percentage changes or at least every 10 minutes; a hard power cut can lose the last minutes.
- Brief charger disconnects (under 60 s) are merged into one charge.
- A charge done partly with the console off: batmon logs nothing then. With clock times in the log the charge is timed on the clock and the off time counts. Without them (RedOnion's and stock Onion's batmon leave `start_time` empty) only the awake time is known, so a level jump of more than 3 % between two entries marks the length as a lower bound: `CHARGE: 0h44+ (1%-100%) OFF 16-99%`.

## Compatibility

| Model | Chipset | Features |
|:---|:---|:---|
| Miyoo Mini Plus (`MIYOO354`) | SigmaStar SSD202D + AXP223 | Everything |
| Miyoo Mini Flip (`MIYOO285`) | SigmaStar SSD202D + AXP223 | Everything |
| Miyoo Mini v1-v4 (`MIYOO283`) | SigmaStar SSD202D, no PMIC | Graph and sessions; `[SELECT]` shows *Hardware Fuel Gauge Not Available* |
| Miyoo A30 / Miyoo Flip | Allwinner A33 / Rockchip RK3566 | Not supported (not Onion) |

## Building from source

```sh
./build.sh     # binary (ARM GNU Toolchain 13.3; $TOOLCHAIN, else a Windows mingw toolchain path)
./package.sh   # release ZIP in dist/
```

- Dynamic executable with its own startup code (`start.S` / `start_init.c`), glibc 2.28-compatible (`stat64` wrapped to `__xstat64@GLIBC_2.4`). Stripped size about 50-70 KB.
- **GitHub Actions:** every push builds on Ubuntu with ARM GNU Toolchain 13.3.rel1 (cached) and uploads the `BatteryMonitorUI` folder as an artifact. A `v*` tag also publishes a release with `BatteryMonitorUI_<tag>_OnionOS.zip`.

Version history: [CHANGELOG.md](../CHANGELOG.md).
