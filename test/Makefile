# Host tests for Battery Monitor: system gcc or clang, no ARM toolchain, no SDL.
#   make -C test
# The functions under test are cut out of the real source, so the tests run the code that ships.

CC ?= cc
CFLAGS ?= -Wall -Wextra -Werror=implicit-function-declaration -std=c99 -g -D_GNU_SOURCE
SRC := ../src/batteryMonitorUI.c
BUILD := ../build/test

.PHONY: all clean test_pmic

all: test_pmic

test_pmic: $(BUILD)/test_pmic
	@$(BUILD)/test_pmic

# Register constants and PMIC functions of the app. A function is cut from its first line to the first
# line that starts with "}" (the sources keep that form; a miss shows as a compile error here).
$(BUILD)/pmic_fns.c: $(SRC) ../src/batteryMonitorUI.h
	@mkdir -p $(BUILD)
	grep -E '^#define (REG_AXP_|AXP_CHGV_|AXP_READBACK_|AXP_SYNC_|AXP_I2C_DEV|BATMON_MAX_UNWRITTEN_S)' $(SRC) > $@
	sed -n '/^static int chgv_code_to_mv(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_units_to_mah(/,/^}/p' $(SRC) >> $@
	grep -E '^#define WAKE_GAP_MS' ../src/batteryMonitorUI.h >> $@
	sed -n '/^static int live_duration(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int is_wake(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int bt_format_state(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int bt_parse_state(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_write_mah16(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_set_capacity(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_set_coulomb_counter(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_sync_check(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_set_charge_voltage(/,/^}/p' $(SRC) >> $@
	sed -n '/^static int axp_set_calibration(/,/^}/p' $(SRC) >> $@

$(BUILD)/test_pmic: test_pmic.c onion_test.h $(BUILD)/pmic_fns.c
	@mkdir -p $(BUILD)
	$(CC) $(CFLAGS) -DPMIC_FNS='"$(abspath $(BUILD))/pmic_fns.c"' -o $@ test_pmic.c

clean:
	rm -rf $(BUILD)
