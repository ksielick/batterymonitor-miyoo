#ifndef DEVICE_MODEL_H__
#define DEVICE_MODEL_H__

#include "utils/file.h"
#include <stdio.h>

#define MIYOO283 283
#define MIYOO285 285 // Miyoo Mini Flip
#define MIYOO354 354

// Same as Onion's device_model.h: the Mini Plus and the Mini Flip have the
// AXP PMIC (i2c-1 @ 0x34, /customer/app/axp_test) and Wi-Fi.
#define IS_MIYOO_PLUS_OR_FLIP() (DEVICE_ID == MIYOO285 || DEVICE_ID == MIYOO354)
#define HAS_AXP() IS_MIYOO_PLUS_OR_FLIP()

static int DEVICE_ID;
static char DEVICE_SN[13];

/**
 * @brief Get device model
 * MM = Miyoo mini
 * MMP = Miyoo mini plus
 */

void getDeviceModel(void)
{
    FILE *fp;
    file_get(fp, "/tmp/deviceModel", "%d", &DEVICE_ID);
}

void getDeviceSerial(void)
{
    FILE *fp;
    file_get(fp, "/tmp/deviceSN", "%[^\n]", DEVICE_SN);
}

#endif // DEVICE_MODEL_H__
