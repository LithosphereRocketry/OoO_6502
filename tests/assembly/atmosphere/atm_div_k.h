#ifndef ATM_DIV_K_H
#define ATM_DIV_K_H

#include <stdint.h>

static /*inline*/ uint32_t mul_upper(uint32_t a, uint32_t b) {
    // Based on:
    // https://stackoverflow.com/questions/28868367/getting-the-high-part-of-64-bit-integer-multiplication
    uint32_t a_lo = a & 0xFFFF;
    uint32_t a_hi = a >> 16;
    uint32_t b_lo = b & 0xFFFF;
    uint32_t b_hi = b >> 16;

    uint32_t ab_lo = a_lo * b_lo;
    uint32_t ab_mid = a_lo * b_hi;
    uint32_t ba_mid = a_hi * b_lo;
    uint32_t ab_hi = a_hi * b_hi;

    uint32_t carry_bit = ((uint32_t)(uint16_t)ab_mid +
                         (uint32_t)(uint16_t)ba_mid +
                         (ab_lo >> 16) ) >> 16;
    return ab_hi + (ab_mid >> 16) + (ba_mid >> 16) + carry_bit;
}

// Divide by 5.25588
static /*inline*/ uint32_t div_k(uint32_t n) {
    uint32_t q = mul_upper(2242422898UL, n);
    uint32_t t = (((n - q) >> 1) + q) >> 2;
    return t;
}

#endif
