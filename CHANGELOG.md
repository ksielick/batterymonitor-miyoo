# Changelog

All notable changes to the standalone **Battery Monitor for Miyoo Mini & Miyoo Mini Plus** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] - Planned / Roadmap

### Planned
- **Wi-Fi off during the battery health test** (`ifconfig wlan0 down` + guaranteed restore) for an even quieter idle baseline.
- **Accelerated Discharge Tool:** drain the battery faster for capacity-learning cycles without leaving a game running for hours.

---

## [2.0.1] - 2026-11-04

### Added
- **Battery Health Test (`[ A: Battery test ]`):** 3-stage internal resistance measurement, ~45 s total:
  - Stage 1: idle baseline (screen dimmed to Onion level 0, app idle under `ondemand`).
  - Stage 2: 2 worker pthreads at 100% load on both Cortex-A7 cores at 1200 MHz.
  - Stage 3: same load at 1600 MHz, switched with Onion's own `cpuclock` tool.
  - Each stage lasts 15 s; only samples after a 7 s settle time (4 Hz) are averaged.
  - $R_{int} = (V_{idle} - V_{load}) / (I_{load} - I_{idle})$, rated **EXCELLENT** (< 160 mΩ), **GOOD** (< 260), **AGED** (< 380), **POOR / REPLACE**.
  - Safeguards: refuses to start below 3.60 V or with the charger connected; aborts below 3.50 V, on charger plug-in, on sleep, or with `[B]`. Original CPU clock, governor and brightness are restored on finish, abort, MENU exit, SIGTERM and `atexit`.
- **Shutdown Voltage setting (`Voff`, REG 31H bits 2-0):** new `[SELECT]` menu row `Shutdown Voltage: < 2.9 V >`, adjustable 2.6–3.1 V in 0.1 V steps with `[LEFT/RIGHT]`, saved with `[A]` and verified by read-back. The write preserves only bits 7 and 4; self-triggering bits 6 (soft restart), 5 (soft wakeup) and 3 (sleep wakeup) are always written as 0.

### Fixed
- **Unrounded manual capacity stepping:** manual capacity adjustment now always snaps to clean 50 mAh multiples (default baseline 3000 mAh for Miyoo Mini Plus). If the PMIC holds an unrounded value from hardware autocalibration (e.g. 3167 mAh), manual capacity adjustment starts at nominal 3000 mAh instead of inheriting the raw unrounded value, and stepping with [LEFT/RIGHT] snaps strictly to round 50 mAh multiples.
- **Calibration status mislabelled:** REG B8H bit 4 is the *correction in progress* flag (AXP221 datasheet v1.2), not a "calibrated" flag. It was shown as `Calibration: Uncalibrated` even after a successful learning cycle. Now shown as `Correction: In progress / Idle`.
- **"Calibration never ends" confusion:** REG B8H bit 5 is a persistent capacity-correction switch, not a one-shot cycle. Relabelled from `Calibration Mode: Learning / Idle` to `Cap. Learning: Enabled / Off`; button now reads `Enable / Disable capacity learning`, and the modal explains it is safe to keep enabled.
- **Silent write failures:** `axp_set_calibration()` now reads REG B8H back after writing and reports `PMIC rejected the change` or `I2C error` instead of always claiming success.

### Changed
- `Design Capacity` renamed to `Total Capacity` (REG E0H/E1H holds the value learned by the PMIC, not only the design value).
- `Battery Level` shows an `(est.)` suffix when REG B9H bit 7 reports the percentage is not yet correctly calculated.
- Calibration guide: documented the 2.9 V PMIC cut-off (REG 31H default `Voff`) and fixed the step count; fixed the Releases link.
- **Documentation:** new [docs/AXP221_REGISTERS.md](docs/AXP221_REGISTERS.md) with translated datasheet register notes (B8H, B9H, E0H-E6H, 31H, ADC) and observed behaviour. README now explains that `BEST` counts only finished sessions, compares Onion low-battery shutdown with the PMIC `Voff` hard cut-off, and documents the GitHub Actions build.
- **GitHub Actions build:** every push builds on Ubuntu with the ARM GNU 13.3.rel1 Linux toolchain and uploads an artifact; `v*` tags publish a release ZIP. `package.sh` now also works on Linux.

---

## [2.0.0] - 2026-11-03

### Added
- **Live `SESSION` Duration Counting:**
  - Solved the legacy issue where `SESSION` playtime froze on the current level until the battery percentage dropped by 1% (or until the 10-minute database flush).
  - Actively advances the current level's awake duration on the fly so `SESSION` ticks up smoothly minute-by-minute during gameplay.
  - Automatically preserves sleep separation (`+3h10 SLEEP`) without corrupting active gameplay time.
- **Direct `SIGCONT` Wake Handling:**
  - Added dedicated `SIGCONT` signal handler inside the application.
  - Instantly queries AXP221 registers via I2C and recomputes telemetry and graphs the millisecond the console wakes up from sleep, without depending on system daemons.
- **Atomic 16-Bit I2C Register Reads:**
  - Implemented 2-byte burst I2C reads (`axp_i2c_read16`) for all 16-bit PMIC registers (`0xE0/0xE1`, `0xE2/0xE3`, `0x78/0x79`, `0x7A/0x7B`, `0x7C/0x7D`).
  - Completely eliminates register tearing and display jitter (e.g. `0 <-> 250 mAh` energy flicker).
- **Coulomb Counter (CC) Activation via Calibration:**
  - Starting battery calibration explicitly enables both Fuel Gauge and Coulomb Counter (`0xB8 |= 0xC0 | 0x20`).
  - Automatically seeds design capacity into `0xE0/0xE1` if uninitialized.
  - When calibration finishes or is stopped, the Coulomb Counter remains permanently active (`0xC0`) to continuously track real mAh.
- **Streamlined Graph Footer Hint:**
  - Added two-line centered navigation prompt `BATTERY MENU` (pastel blue) and `[SELECT]` (white) in `font_Arkhip`, seamlessly aligned with session and voltage labels without background boxing.
- **Interactive Battery Test Modal:**
  - Added 4th action item `[ A: Battery test ]` with comprehensive player notice regarding temporary screen dimming and Wi-Fi turn-off for clean baseline measurements.
- **Live AXP221 PMIC Telemetry & Fuel Gauge Overlay (`[SELECT]` Button):**
  - **Real-Time Telemetry (1 Hz poll):**
    - High-precision cell voltage in millivolts (registers `0x78/0x79`).
    - Instantaneous charge / discharge current in mA (registers `0x7A-0x7D`).
    - True remaining electrical energy in **milliampere-hours (mAh)** from hardware Coulomb counter (`0xE2/0xE3` $\times 1.456\text{ mAh}$).
    - Registered cell design capacity (`0xE0/0xE1`).
    - Current system battery percentage (`0xB9`).
  - **Dual Fuel Gauge Metrics:**
    - **Voltage-based (OCV %):** Raw open-circuit voltage estimate (`0xE4 & 0x7F`). Fast and responsive, but reflects instantaneous cell load and internal resistance drop.
    - **Hardware Counter (CC %):** Integrated Coulomb counter (`0xE5 & 0x7F`). Monotonic, smooth, and immune to momentary load dips during gameplay.
    - Real-time status display of fuel gauge state (`Active`, `Learning`, `Calibrated`).
  - **Hardware Controls & Calibration Wizard:**
    - Battery design capacity configuration (`< 2600 mAh >` in 50 mAh increments with `[D-Pad LEFT/RIGHT]`, saved to PMIC NVRAM via `[A]`).
    - Coulomb counter 100% synchronization (`[A]` seeds `0xE2/0xE3` upon reaching full charge).
    - Hardware autocalibration toggle (`0xB8` bit 5) protected with a confirmation modal explaining the full charge $\rightarrow$ empty $\rightarrow$ full charge learning cycle.
  - **Non-AXP Hardware Safeguard:**
    - Graceful fallback for Miyoo Mini v1-v3 models (lacking AXP221): displays "HARDWARE FUEL GAUGE NOT AVAILABLE" without erroneous I2C writes or crashes.
- **Enhanced Graph & Session Analytics:**
  - **Session & Charge Stepping (`[L1] / [R1]`):**
    - Interactively step backward and forward through previous play sessions and charging stretches.
    - Visual highlight: sessions on battery are tinted with Onion purple (`#8861FC`), while charging stretches are tinted with green (`#7DDB8F` at 30%).
    - Informative captions: shows exact duration, percentage gained/lost, and time spent topped off at 100% (e.g. `CHARGE: 0h46 (86%-100%) +3h39 AT 100%`).
  - **Non-Linear Runtime Prediction (`LEFT`):**
    - Predicts remaining battery life by constructing an empirical discharge curve from log history and scaling it against current session load.
    - Replaces the inaccurate straight-line estimate with an exponential/curved projection.
  - **Sleep Drain Tracking:**
    - Detects and logs sleep duration and battery cost from database timestamps (e.g. `+3h10 SLEEP -12% (3.8%/H)`).
  - **Zoom Controls (`[L2] / [R2]`):**
    - Switch between 1-hour, 2-hour, and 4-hour divisions on the time axis.
- **Standalone Build & Packaging Automation:**
  - Complete, self-contained build environment in repository root (`build.sh`) linking against bundled ARM GNU Toolchain 13.3 (`GLIBC_2.4`, `GLIBC_2.7`, `GLIBC_2.17`).
  - Automated package generator (`package.sh`) producing release-ready `BatteryMonitorUI_v2.0_OnionOS.zip`.

### Changed
- **UI Design & Typography Overhaul:**
  - Enlarged telemetry instrument cards to 186 px height with generous 34 px row pitch.
  - Added subtle horizontal card dividers (`#1c283c`) separating each metric.
  - Upgraded table keys and values to `font_Arkhip` (15 pt) for superior legibility on the 3.5" 640x480 screen.
  - Upgraded footer pill badges and modal dialog text from `font_tiny` (10 pt) to `font_small` (12 pt).
  - Removed cramped explanation text box from the on-screen overlay; comprehensive explanations moved to documentation.
  - Changed charging curve graph color from pink-red (`#FFAAAA`) to intuitive charging green (`#7DDB8F`).
  - Switched area fill under graph from dot-grid pattern to a solid 30% alpha fill.
- **CPU & Power Optimization:**
  - Implemented adaptive input polling (`INPUT_POLL_IDLE_MS = 50 ms`, `INPUT_POLL_ACTIVE_MS = 16 ms`).
  - Slashed idle CPU usage from 100% of a core down to **<0.10%** single-core.
  - Processor automatically scales down to its minimum power-saving step (**400 MHz**) under the `ondemand` governor when viewing the app.
  - Zero I2C bus traffic during graph viewing; telemetry polling strictly rate-limited to 1 Hz when the `[SELECT]` overlay is active.

### Fixed
- **Loop-Tail Flush for Oldest Run:** Fixed an issue where `compute_graph()` failed to flush the oldest session or charge in a database if `is_charging` didn't change at the end of the query.
- **Buffer & Duration Bounds:** Imported safety bounds preventing out-of-bounds array writes on corrupted or implausible database durations.
- **Image Load Crash Guard:** Added null checks in `safeBlitSurface()` preventing crashes when optional UI assets fail to load.

---

## [1.0.0] - Baseline Stock OnionOS Release

### Features
- Initial stock OnionOS Battery Monitor implementation.
- Basic historical battery drain line graph based on `/mnt/SDCARD/.tmp_update/logs/batmon.db`.
- Fixed-window time zoom on `[L1]/[R1]`.
- Linear battery drain projection (`LEFT`).
- All-time record session display (`BEST`).

