#include "atmosphere.h"

static volatile char* const out = (volatile char* const) 0x4000;
static volatile char* const done = (volatile char* const) 0x4100;

static const uint32_t base_pres = 101325;
static const uint32_t pres = 30000;

int main() {
    uint8_t i;
    uint32_t alt = atm_pressure_alt(pres, base_pres);
    for(i = 0; i < 4; i++) {
        *out = alt & 0xFF;
        alt >>= 8;
    }
    *done = 0;
    while(1);
}