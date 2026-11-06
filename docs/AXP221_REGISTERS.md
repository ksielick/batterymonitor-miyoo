# AXP223 / AXP221 PMIC — Register Notes (Miyoo Mini Plus)

Reference for the registers Battery Monitor reads and writes. Hardware on the Miyoo Mini Plus motherboard is the **X-Powers AXP223** (part of the AXP22x PMIC family, fully register-compatible with AXP221). Sources: **X-Powers AXP223 Datasheet Revision 1.1** and **AXP221 Datasheet Revision 1.2**, translated where needed. Behaviour notes marked *observed* come from real use on a Miyoo Mini Plus, not from the datasheet.

- I2C bus `/dev/i2c-1`, address `0x34`.
- Datasheet copies: [monitor.espec.ws](https://monitor.espec.ws/download.php?id=154987). The linux-sunxi link quoted in kernel device trees (`dl.linux-sunxi.org/AXP/AXP221 Datasheet V1.2 20130326 .pdf`) was dead when we checked (2026-11).
- Text extraction tip: `pdftotext` drops the Chinese text unless poppler-data CMaps are installed; `pypdf` (+ `cryptography`, the PDF is AES-encrypted) extracts it correctly.

## Fuel gauge

### REG B8H — Fuel gauge control (default `C0H`)

| Bit | Meaning | R/W | Default |
|:---|:---|:---|:---|
| 7 | Fuel gauge enable (0 off, 1 on) | RW | 1 |
| 6 | Coulomb counter enable (0 off, 1 on) | RW | 1 |
| 5 | Battery total capacity **correction (learning) enable** (0 off, 1 on) | RW | 0 |
| 4 | Capacity correction **status**: 0 = not correcting, 1 = correcting in progress | RW | 0 |
| 3-0 | Reserved, do not change | RW | 0 |

- Bit 5 is a **persistent switch**, not a one-shot cycle. It stays `1` after a successful learning cycle. Shown in the app as `Cap. Learning: Enabled / Off`.
- Bit 4 = `0` after a full charge is normal: nothing is being corrected *right now*. Versions ≤ 2.0.0 wrongly showed this as `Uncalibrated`.
- *Observed:* learning was enabled, the battery discharged to ~3.15 V (under load), then charged to 100%. Afterwards REG E0H/E1H held **3167 mAh** on a stock 3000 mAh cell, while bit 5 stayed `1` and bit 4 read `0`.

### REG B9H — Battery level (default `64H`)

| Bit | Meaning | R/W |
|:---|:---|:---|
| 7 | Percentage correctly calculated (0 no, 1 yes) | R |
| 6-0 | Battery level 0–100 % | R |

The app adds `(est.)` to `Battery Level` while bit 7 = 0.

### REG E0H / E1H — Battery total capacity

- E0H bit 7: capacity configured flag (0 not configured, 1 configured).
- E0H bits 6-0: capacity bits [14:8]. E1H bits 7-0: capacity bits [7:0].
- Capacity = value × **1.456 mAh**.
- Written by the app (`Battery Capacity` → `[A] Save`, always a multiple of 50 mAh) **and by the PMIC itself** when capacity learning finishes. A value that is not a multiple of 50 (e.g. 3167) came from the PMIC.

### REG E2H–E5H — not documented

Datasheet v1.2 does not describe E2H–E5H. The app reads them as follows (layout taken from vendor driver conventions, **not verified against documentation**):

- E2H/E3H: Coulomb counter remaining charge, × 1.456 mAh (`Energy Remaining`). Written by `Sync counter to 100%`.
- E4H & 0x7F: OCV-based percentage (`Voltage (OCV)`).
- E5H & 0x7F: Coulomb-counter percentage (`Coulomb Ctr (CC)`).

### REG E6H — Low battery warning thresholds (default `A0H`)

Bits 7-4: warning level 1 (5–20 %); bits 3-0: warning level 2 (0–15 %). Not used by the app.

## Power-off

### REG 31H — Wakeup control & Voff (default `03H`)

| Bit | Meaning | R/W | Default |
|:---|:---|:---|:---|
| 7 | Pull PWROK low during wakeup | RW | 0 |
| 6 | **Soft restart** — writing 1 reboots the PMU (self-clearing) | RW | 0 |
| 5 | **Soft wakeup** — writing 1 restores all outputs (self-clearing) | RW | 0 |
| 4 | When wakeup is enabled: 0 = IRQ can trigger wakeup, 1 = IRQ works but cannot wake | RW | 0 |
| 3 | Sleep-mode wakeup enable (self-clearing after write; must be re-armed before each sleep) | RW | 0 |
| 2-0 | **Voff**: `000` 2.6 V, `001` 2.7, `010` 2.8, `011` **2.9 (default)**, `100` 3.0, `101` 3.1, `110` 3.2, `111` 3.3 V | RW | `011` |

- Datasheet §9.2.4: when **ALDOIN** falls below Voff, the AXP221 enters shutdown and turns off every output except LDO1. **No delay or debounce is documented.** Treat it as an immediate **hard power cut**: nothing gets saved and SD writes in progress may be interrupted.
- ALDOIN is measured **under load**. With ~150 mΩ internal resistance, a 0.5 A load step sags ~75 mV, so a 3.1 V Voff can trigger while the resting voltage is still ~3.2 V.
- The app writes `(old & 0x90) | code`: it keeps bits 7 and 4 and never writes 1 to bits 6, 5 or 3.
- *Open question:* whether Voff survives a power cycle. The PMIC keeps its registers while the battery is connected, but Onion or the firmware may rewrite REG 31H at boot.

## Telemetry (ADC)

| Register | Quantity | Step |
|:---|:---|:---|
| 78H/79H | Battery voltage (12 bit: `high << 4 \| low & 0x0F`) | 1.1 mV |
| 7AH/7BH | Battery charge current | 1 mA |
| 7CH/7DH | Battery discharge current | 1 mA |
| 01H bit 6 | Charging indicator | — |

16-bit pairs are read in one 2-byte I2C transfer to avoid tearing between bytes.

## Related system interfaces (Onion OS)

- **CPU clock:** Onion's `cpuclock` tool (`/mnt/SDCARD/.tmp_update/bin/cpuclock`). Run without arguments it prints the current MHz; `cpuclock <MHz>` sets the governor to `userspace` and reprograms the MPLL. Onion restores with `cpuclock <old MHz>` and then writes the old governor back to `/sys/devices/system/cpu/cpufreq/policy0/scaling_governor`. The battery test does the same.
- **Brightness:** `/sys/devices/soc0/soc/1f003400.pwm/pwm/pwmchip0/pwm0/duty_cycle`. Onion level *n* → raw `round(3·e^(0.350656·n))`; level 0 = raw 3, still visible. *Observed:* dimming the screen dropped the draw from ~420 mA to ~276 mA.
- **Battery log:** `batmon` writes `/mnt/SDCARD/.tmp_update/logs/batmon.db` when the percentage changes (and on charger events), or at least every 10 minutes. After a hard power cut the last minutes of a session can be missing from the log.
