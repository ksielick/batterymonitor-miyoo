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

## [2.3] - 2026-11-12

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

