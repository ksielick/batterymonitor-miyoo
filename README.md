# Onion Battery Monitor V2

[![Onion OS](https://img.shields.io/badge/Onion_OS-v4.2_%7C_v4.3_%7C_v4.4-blue.svg)](https://github.com/OnionUI/Onion)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-yellow.svg)](https://www.gnu.org/licenses/gpl-3.0)

A better **Battery Monitor** app for Onion OS on the **Miyoo Mini**, **Mini Plus** and **Mini Flip**.

![Battery Monitor V2 menu](docs/screenshot_axp_menu.png)

## What it does

- **Fixes the jumpy battery % on the Mini Plus and Mini Flip.** No more 25 % drops when a game starts, hours "stuck" at 10 %, or jumps after sleep. Set it up once (below) and the percentage shown everywhere in Onion becomes steady.
- **Shows what your battery is doing right now:** voltage, how much power the console draws, how many mAh are left.
- **Better history graph:** browse your past play sessions and charges, see how long a charge took and how much battery sleep costs.
- **Battery health check:** a 45-second test that tells you how worn your battery is.

## Install

1. Download `BatteryMonitorUI_v2.1_OnionOS.zip` from [Releases](https://github.com/ksielick/batterymonitor-miyoo/releases).
2. Put the SD card in your computer. Optionally, back up the old `App/BatteryMonitorUI` folder.
3. Copy the `BatteryMonitorUI` folder from the ZIP into `App/` on the card, replacing the old one.
4. Start **Battery Monitor** from **Apps**.

## Controls

| Button | What it does |
|:---|:---|
| `SELECT` | Open / close the battery menu |
| `L1` / `R1` | Previous / next play session or charge |
| `L2` / `R2` | Zoom the graph |
| `LEFT` / `RIGHT` | Scroll the graph, or change a value in the menu |
| `UP` / `DOWN` | Move in the menu |
| `A` | Save / confirm |
| `B` | Back |
| `MENU` | Exit |

## Set up your battery (Mini Plus and Mini Flip, once)

This makes the battery % steady. Do it in this order:

1. **Charge to 100 %** (until the red light on the console goes off).
2. Open Battery Monitor, press `SELECT`, set **Battery Capacity** (3000 mAh for the original battery) and press `A`.
   *Energy Remaining* and *Total Capacity* should now show about the same number. If not, press **Set current capacity to 100%**.
3. Press **Enable capacity learning** and confirm.

That's it. Your battery is probably not as good as new, so the console will learn its real capacity from the next full discharge (see below). Until then, the last few percent may run out a bit early.

> Why charge first? If you set the capacity while charging, the console counts too much charge and the % runs high.

## Teach it your real battery (optional, one cycle)

Old batteries hold less than 3000 mAh. One full cycle lets the console measure yours:

1. **Before you start:** in Onion's settings, turn **Low batt.: Save and exit** off, set **Sleep timer** to **Never**, and turn **Wi-Fi off**.
2. **Play down to about 10 %**, save your game, go back to the main menu and **put the console to sleep** (short press of Power).
3. **Leave it asleep until it switches itself off** (about 1-1.5 hours). This is safe for the battery.
4. **Charge straight to 100 % in one go.** In the battery menu, *Correction* shows **In progress** during this charge. If it says *Idle*, the console did not run all the way down; try again next time.
5. Turn **Low batt.: Save and exit** back on.

After that charge, *Total Capacity* shows what your battery really holds (often well below 3000 mAh on an old battery).

> Why asleep? At the very end the console cuts the power instantly, with no saving. Asleep, nothing is writing to the SD card, so the card stays safe. Still, back up your SD card first, and check it on a PC if the console ever shuts off this way during a game.

## Good to know

- **Shutdown Voltage:** leave it at **2.9 V** unless you know why you want another value. It is the point where the console cuts power on its own.
- **Battery test:** run it on battery (not charging) with a fair charge left (it needs at least 3.6 V), ideally with Wi-Fi off.
- **Mini v1-v4:** the graph and history work; the battery menu does not, as these models lack the battery chip it needs.
- **Not supported:** Miyoo A30 and Miyoo Flip (they don't run Onion).

## More details

Every value in the menu, how the battery chip behaves, the low-battery cut-off and the SD card, and how to build the app: **[docs/TECHNICAL.md](docs/TECHNICAL.md)**. Chip registers: [docs/AXP221_REGISTERS.md](docs/AXP221_REGISTERS.md). Version history: [CHANGELOG.md](CHANGELOG.md).

## Credits

- Original app by the **Onion UI team** ([OnionUI/Onion](https://github.com/OnionUI/Onion)).
- Battery fixes based on work by **Amiga500** ([Amiga500/Onion](https://github.com/Amiga500/Onion)).
- V2 by **ksielick**.
- License: **GPL-3.0**.
