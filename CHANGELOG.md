# Changelog

All notable changes to the standalone **Battery Monitor for Miyoo Mini, Mini Plus & Mini Flip** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - Planned / Roadmap

### Planned
- **Wi-Fi off during the battery health test** (`ifconfig wlan0 down` + guaranteed restore) for an even quieter idle baseline.
- **Accelerated Discharge Tool:** drain the battery faster for capacity-learning cycles without leaving a game running for hours.
- **Safe drain mode:** near the end of a capacity-learning discharge, stop the apps that write, `sync`, and remount the SD card read-only, so the PMIC `Voff` hard cut cannot corrupt it. Remounting read-only while Onion runs is not tested yet. This would also change the Accelerated Discharge idea: a drain under load ends with a hard cut while the card may be busy.

---

## [2.3.3] - 2026-11-25

### Fixed
- **A sleep that ran the battery down until the console switched itself off showed `-0%`.** The cost of a sleep was counted only up to the next level logged on battery; when the next entry was a charge (the console off at 1 %, then the charger), the drop was lost. It is now counted down to the charge's first level: a 10 h 05 sleep from 100 % reads `-98%`.
- **A charge across a clock jump showed `38h45`.** After the battery ran flat the clock fell back, and the network set it again in the middle of the next charge, so the clock span of that charge was 37 h too long. A gap of 30 min or more below 95 % with under 2 % per hour gained now counts as a clock jump, and the charge is timed by awake time (`1h45`).

### Changed
- **Clearer session line** (L1/R1): levels first, then labelled times, e.g. `100% > 2%   PLAY 0H01   SLEEP 10H05 -98%` and `CHARGE 2% > 99%   1H45   +0H20 AT 99%`. It replaces `SESSION: 0H01 (100%-100%) +10H05 OFF/SLEEP -98% (9.7%/H)`, which read as no battery used and touched the L2/R2 icons. A session that ends in such a sleep ends at the level after it. The sleep rate per hour is no longer shown.

---

## [2.3.2] - 2026-11-17

### Fixed
- **"Set current capacity to 100%" asks first.** It shows the change (`3755 mAh -> 3050 mAh`) and waits for `A`. It refuses while the battery charges or reads below 4.00 V: on a battery that is not full it would make the percentage read too high.
- **Capacity and counter writes are checked.** The app reads the value back from the PMIC and reports a write the PMIC did not keep, instead of always showing "Saved".
- **Capacity learning switch keeps the capacity it cannot read.** A failed read of the capacity register was taken for "no capacity set", and the default was written over a good value.
- **A saved 3000 mAh was shown as 2999 mAh.** The PMIC counts in units of 1.456 mAh, so 3000 mAh is held as 2999.4. A value that is the stored form of a multiple of 50 mAh is now shown as that multiple.
- **Sleep was drawn as play time in the session that is going on.** On a console whose batmon logs clock times, the graph and the `SESSION` time of the current session counted every sleep as time awake (a 3 h 28 session with 22 h of sleep read `25h35`), and the header showed no sleep. Sleep is now left out of the graph and shown in the header (`+22h05 OFF/SLEEP -2%`), as it already was for finished sessions.
- **The newest entry no longer counts a sleep as play time** (review point 6). Its live time was the clock since the entry began, so a sleep without a level change went into `SESSION` and the graph, and days switched off could push the rest of the graph off the screen. It is now the logged time plus the time since batmon last wrote the log, at most 630 s (batmon writes every 600 s awake). A sleep going on in the newest entry counts in the header's OFF/SLEEP time.
- **A slow screen update no longer aborts the battery test** (review point 7). A gap of 2 s between two passes of the main loop was taken for a wake from sleep, so the database, `cpuclock` or the test's own load on both cores could end the test with "Interrupted by sleep". A wake is now SIGCONT (Onion's sleep stops the app and continues it), with a 30 s gap kept only as a fallback.
- **A battery test killed with SIGKILL no longer leaves 1600 MHz and a dim screen** (review point 8). The test saves the clock, governor and brightness to `/tmp/batterymonitor_bt_restore` before it changes them; `launch.sh` runs `batteryMonitorUI --restore` after the app ends, and every start of the app restores from the file too.

### Changed
- **The header says `OFF/SLEEP`, not `SLEEP`.** The log alone cannot tell a sleep from a console switched off. A header too wide for the screen drops the sleep rate first, then the date. A rate below 1 %/h has two decimals (2 % over 22 h read `0.0%/H`, now `0.09%/H`).
- **The header no longer shows the session's start date** (`16.11 05:57`): it read as unclear and took the room the sleep needs. `SUB_TITLE_SHOW_DATE` in `batteryMonitorUI.h` brings it back.
- **The battery test says what to do when the load step is too small:** "Load step too small - turn Wi-Fi off and retry". On a Mini Plus with Wi-Fi on the test read 407 mA idle and 481 mA under load (no result); with Wi-Fi off 258 mA and 430 mA, 209 mOhm.

### Added
- **Battery test: a 1800 MHz stage on the Mini Plus**, after 1200 and 1600 MHz (Onion's `cpuclock` overclock, as DraStic uses it), to show how the current scales with the clock. The test then takes about 60 s. The result uses the stage with the largest current step.
- **Host tests** of the PMIC code (`make -C test`, 30 tests on a simulated AXP223), run by the GitHub build before every artifact and release.

### Measured
- A full charge at **Full 4.20 V** on a Mini Plus (2026-11-15): the reading climbed to 4.27 V at 1 A, held 4.24-4.25 V while the current fell, the charge stopped at 180 mA (10 % of the 1800 mA setting), and the resting battery read 4.20 V. The reading during a charge is above the battery's own voltage (about 0.2 ohm between them), so 4.2x V on the screen while charging is not an overcharge.
- A charge at **~90% 4.10 V** from an empty battery (2 %, 3.46 V at 478 mA) on the same Mini Plus (2026-11-17): the reading held 4.13-4.16 V in the constant-voltage phase, the charge stopped at 184 mA after 142 min, the resting battery read 4.09 V, and 1972 mAh went in. The gauge then showed 68 % by its counter and 94 % by voltage (OCV). What share of a full 4.20 V charge this is has not been measured: the two charges started from different states.

The first three fixes and review points 6-8 come from Amiga500's review of RedOnion PR #332.

---

## [2.3.1] - 2026-11-15

### Fixed
- **Charge Limit: "~95% 4.15 V" really set a 4.22 V target.** v2.3 used the AXP209's voltage table. On the AXP221/AXP223 the codes of REG 33H bits 6-5 are `00` = 4.10 V, `01` = 4.22 V, `10` = 4.20 V, `11` = 4.24 V (AXP221 datasheet v1.2, section 10.2.27). Found by Amiga500.
  - The menu now offers only **Full 4.20 V** and **~90% 4.10 V**; both always set what they show.
  - A console still set to the old "~95%" shows `Now 4.22 V`, and the row opens on Full, marked `*`: press `A` to save.
  - 4.22 V and 4.24 V are never offered and the write refuses them.

---

## [2.3] - 2026-11-12

> **Wrong in this entry:** "4.15 V (~95%)" set 4.22 V, and the fourth code is 4.24 V, not 4.35 V. Fixed in 2.3.1.

### Added
- **Charge Limit** in the battery menu (Mini Plus / Mini Flip): sets the PMIC charge target voltage (REG 33H bits 6-5) to **4.20 V (Full)**, **4.15 V (~95%)** or **4.10 V (~90%)**; 4.35 V is never offered. A lower limit charges less but is easier on the battery. Asked for by a user who expected *Battery Capacity* to cap the charge: that setting only sizes the fuel gauge. Tested on a Mini Plus with RedOnion 4.5.0.

### Changed
- The settings rows are now 25 px apart, to fit the new row.

---

## [2.2.3] - 2026-11-09

### Fixed
- **Charge length when the console was off for part of it.** batmon logs nothing while the console is off, and without clock times in the log (RedOnion's and stock Onion's batmon leave `start_time` empty) a charge was timed on the awake time only: a 1-100 % charge mostly done with the console off showed `0h44`. A level jump of more than 3 % between two entries of a charge now marks the length as a lower bound and shows the jump: `CHARGE: 0h44+ (1%-100%) OFF 16-99%`. With clock times the charge is timed on the clock as before. Tested on a Mini Plus with RedOnion 4.5.0.

---

## [2.2.2] - 2026-11-09

### Changed
- Learning dialog step 2 reads "Discharge down to 1%, then plug in the charger." (was "Play down to 1%..."): leaving the console on works as well as playing. README follows.

---

## [2.2.1] - 2026-11-09

### Changed
- **Capacity learning needs no power cut.** Discharging to 1 % and plugging in the charger is enough: *Correction* turned *In progress* when the charger went in, with the console still running (observed on a Mini Plus). The learning dialog now says "Play down to 1%, then plug in the charger" instead of sleeping until the PMIC powers off at `Voff`. README and `docs/TECHNICAL.md` follow; this avoids the hard power cut and its SD card risk.

---

## [2.2] - 2026-11-08

Tested on a Miyoo Mini Plus with Onion 4.4.0-beta and RedOnion 4.5.0.

### Changed (tested on a Mini Plus with a factory-reset PMIC)
- **Unconfigured PMIC on screen:** *Energy Remaining* and *Total Capacity* show `Not set` instead of `0 mAh` while no capacity is saved, and *Coulomb Ctr (CC)* shows `--` while REG E5H bit 7 is clear (it reads a meaningless 100 % then).
- **Next-step hint** on the right of *BATTERY SETTINGS & ACTIONS*: `Charge to 100%, then save capacity`, or `Battery full: save capacity now` once a charge has finished at 100 %; with a capacity set, `Counter high: sync at 100%` when the counter is more than 50 mAh above the capacity (the PMIC never trims it back).
- **Saving a capacity while charging asks first** (*STILL CHARGING*): the PMIC seeds its counter from the voltage, which reads high while charging. `[A] Save anyway` / `[B] Cancel`.
- **Capacity learning dialog** follows the safe order: charge to 100 % and save the capacity first (highlighted while no capacity is set), sleep through the last ~10 % until the PMIC powers off, then charge straight to 100 % (*Correction: In progress*).

### Documentation
- README rewritten for players (what it does, install, controls, one-time battery setup, optional learning cycle); register values, PMIC behaviour, the `Voff` cut-off, SD card notes and build steps moved to `docs/TECHNICAL.md`.
- Calibration starts with the safe order **charge to 100 % → set the battery capacity → enable capacity learning**, with the measured reason: saving a capacity makes the PMIC seed the Coulomb counter from the voltage, which reads high while charging (counter 3085 mAh of 2800, never trimmed by the PMIC). *Correction* turns *In progress* only in the charge after a PMIC power-off at `Voff` (observed).

---

## [2.1] - 2026-11-07

### Added
- **Miyoo Mini Flip (`MIYOO285`) support for the PMIC features**: live telemetry, Coulomb counter, Capacity Learning, Shutdown Voltage and charging detection. They now check `HAS_AXP()` (Mini Plus or Mini Flip, as in Onion's `device_model.h`) instead of the Mini Plus only. Both models have the same AXP on `/dev/i2c-1` @ 0x34 and the same `/customer/app/axp_test`. Not yet tested on real Mini Flip hardware.
- The "Hardware fuel gauge not available" dialog now lists which models have the PMIC features (Mini Plus, Mini Flip), which get the graph and session tracking only (Mini V1-V4), and which are not supported (A30, Miyoo Flip).

### Fixed
- `battery_isCharging()`: no crash when `axp_test` cannot be started, and no uninitialised value when it prints nothing.

### Changed (docs)
- README: calibration step 3 now drains the last ~10 % with the console **asleep** (apps stopped, SD card idle about 35 s after it falls asleep, ~245 mA), instead of playing until the cut-off. New section *Hard power-off and the SD card*: a `Voff` cut can damage files that were not being written (shared FAT sectors, SD erase blocks). Observed case: a corrupted `retroarch.cfg` was regenerated with RetroArch defaults.

---

## [2.0] - 2026-11-06

### Added
- **Live PMIC Telemetry & Fuel Gauge Overlay (`[SELECT]` Button):**
  - High-precision cell voltage in millivolts (registers `0x78/0x79`).
  - Instantaneous charge / discharge current in mA (registers `0x7A-0x7D`).
  - True remaining electrical energy in **milliampere-hours (mAh)** from hardware Coulomb counter (`0xE2/0xE3` $\times 1.456\text{ mAh}$).
  - Dual fuel gauge metrics: fast voltage-based estimate (**OCV %**) vs smooth, monotonic hardware Coulomb counter (**CC %**).
  - Graceful fallback for older Miyoo Mini models lacking PMIC: displays *"HARDWARE FUEL GAUGE NOT AVAILABLE"*.
- **Hardware PMIC Battery Calibration Wizard:**
  - 1-cycle capacity learning setting (`REG B8H bit 5`) teaching the PMIC your cell's true degraded or upgraded capacity.
  - Interactive battery capacity profile adjustment (`< 3000 mAh >` in 50 mAh increments with `[D-Pad LEFT/RIGHT]`).
  - One-click Coulomb counter synchronization to 100% on full charge.
- **Battery Health Test (`[ A: Battery test ]`):**
  - 3-stage internal resistance measurement (~45 s): idle baseline (screen dimmed) -> 2 worker pthreads at 1200 MHz -> same load at 1600 MHz.
  - Worker threads hard-pinned to Core 0 and Core 1 (`pthread_setaffinity_np`) for full dual-core saturation.
  - Screen brightness boosted to 100% during stress stages to guarantee $\Delta I > 150\text{ mA}$ for noise-free $R_{int}$ calculation.
  - Rates cell: **EXCELLENT** (< 160 mΩ), **GOOD** (< 260), **AGED** (< 380), **POOR / REPLACE**.
  - Safeguards: aborts below 3.50 V, on charger plug-in, on sleep, or with `[B]`. Restores CPU clock, governor, and brightness on exit.
- **Shutdown Voltage Setting (`Voff`, REG 31H):**
  - New `[SELECT]` menu row `Shutdown Voltage: < 2.9 V >`, adjustable 2.6–3.1 V in 0.1 V steps with `[LEFT/RIGHT]`, saved with `[A]` and verified by read-back.
- **Auto-Clearing False Low-Battery Shutdown (`/tmp/.lowBat`):**
  - OnionOS `keymon` sets `/tmp/.lowBat` when battery hits <= 1%, but never clears it after charging begins. BatteryMonitorUI now automatically unlinks `/tmp/.lowBat` whenever charging or battery > 3%, preventing false shutdowns when exiting games.
- **Adjacent Charging Session Merging:**
  - Brief charger disconnects (< 60 s) discarded as noise in SQLite logs previously split a single charge into two separate sessions. `compute_graph()` now seamlessly merges adjacent charging sessions into a single continuous stretch with combined duration, level bounds, and unified green charging curve.
- **Stock OnionOS Live `SESSION` Tracking:**
  - Solves the legacy issue where playtime froze on the current level until percentage dropped; derives session start time directly from `stat(BATTERY_LOG_FILE).st_mtime - duration` on stock OnionOS daemons.
- **Direct `SIGCONT` Wake Handling:**
  - Added dedicated `SIGCONT` signal handler inside the application. Instantly queries PMIC registers and updates graphs the millisecond the console wakes from sleep.
- **Atomic 16-Bit I2C Burst Reads:**
  - Implemented 2-byte burst I2C reads (`axp_i2c_read16`) for all 16-bit PMIC registers, eliminating register tearing and display jitter.
- **Enhanced Graph & Session Analytics:**
  - Session & charge stepping with `[L1] / [R1]` (purple for battery play, charging green `#7DDB8F` for charges).
  - Time zoom with `[L2] / [R2]` (1h, 2h, 4h divisions).
  - Empirical curved discharge projection (`LEFT`).
  - Sleep drain detection (`+3h10 SLEEP -12%`).

### Changed
- **UI Terminology:** Refactored headers, subheaders, and error modals from "AXP221" to generic "PMIC" to reflect the actual **AXP223** chip present on Miyoo Mini Plus motherboards.
- **UI Design & Typography:** Enlarged telemetry cards to 186 px height, added card row pitch, upgraded typography to `font_Arkhip` (15 pt) and `font_small` (12 pt).
- **CPU & Power Optimization:** Adaptive input polling (50 ms idle / 16 ms active), idle CPU usage slashed to **<0.1%**, 400 MHz power-saving floor under `ondemand`. Zero I2C bus traffic during normal gameplay.

### Fixed
- **glibc Compatibility:** Wrapped `stat` and `stat64` to `__xstat`/`__xstat64@GLIBC_2.4` and explicitly linked `libpthread.so.0` (`-pthread -Wl,--no-as-needed -lpthread`), guaranteeing compatibility down to glibc 2.17.
- **Loop-Tail Flush for Oldest Run:** Fixed an issue where `compute_graph()` failed to flush the oldest session or charge in a database if `is_charging` didn't change at the end of the query.
- **Buffer & Duration Bounds:** Added bounds checks preventing out-of-bounds array writes on corrupted or implausible database durations.

---

## [1.0.0] - Baseline Stock OnionOS Release

### Features
- Initial stock OnionOS Battery Monitor implementation.
- Basic historical battery drain line graph based on `/mnt/SDCARD/.tmp_update/logs/batmon.db`.
- Fixed-window time zoom on `[L1]/[R1]`.
- Linear battery drain projection (`LEFT`).
- All-time record session display (`BEST`).

