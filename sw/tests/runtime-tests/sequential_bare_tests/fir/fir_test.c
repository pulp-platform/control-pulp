/*
 * Copyright (C) 2018 ETH Zurich and University of Bologna
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * Mantainer: Luca Valente, luca.valente2@unibo.it
 */
#include <stdio.h>
#include "common.h"

#if WORD==16
#define FILTER_SIZE 10

int16_t input_l2[200] = {
  0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff,
  0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800,
  0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800,
  0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400,
  0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff,
  0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800,
  0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800,
  0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400,
  0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff,
  0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800,
  0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800,
  0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400,
  0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff,
  0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800,
  0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800,
  0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400,
  0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff,
  0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800,
  0x0200, 0xf800, 0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800,
  0xf300, 0x0400, 0x0000, 0x07ff, 0x0c00, 0x0800, 0x0200, 0xf800, 0xf300, 0x0400
};

int16_t filter_l2[FILTER_SIZE] = {
  0x0c60, 0x0c40, 0x0c20, 0x0c00, 0xf600, 0xf400, 0xf200, 0xf000, 0x0c60, 0x0c40
};

int16_t input[200] __sram;
int16_t filter[10] __sram;
int16_t output[200] __sram;

extern void fir16(const int16_t *in, const int16_t *coeffs, int16_t *out,
                unsigned in_length, unsigned coeffs_length);

extern void fir16_dotp(const int16_t *in, const int16_t *coeffs, int16_t *out,
                unsigned in_length, unsigned coeffs_length);

const char* get_testname() {
  return "fir16";
}

#endif

#if WORD==8

#define FILTER_SIZE 12

int8_t input_l2[200] = {
  0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07,
  0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08,
  0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8,
  0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04,
  0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07,
  0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08,
  0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8,
  0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04,
  0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07,
  0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08,
  0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8,
  0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04,
  0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07,
  0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08,
  0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8,
  0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04,
  0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07,
  0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08,
  0x02, 0xf8, 0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8,
  0xf3, 0x04, 0x00, 0x07, 0x0c, 0x08, 0x02, 0xf8, 0xf3, 0x04
};

int8_t filter_l2[FILTER_SIZE] = {
  0xc6, 0xc4, 0xc2, 0xc0, 0x60, 0x40, 0x20, 0x00, 0xc6, 0xc4, 0x20, 0x17
};

int8_t input[200] __sram;
int8_t filter[12] __sram;
int16_t output[200] __sram;

extern void fir8(const int8_t *in, const int8_t *coeffs, int16_t *out,
                unsigned in_length, unsigned coeffs_length);

extern void fir8_dotp(const int8_t *in, const int8_t *coeffs, int16_t *out,
                unsigned in_length, unsigned coeffs_length);

const char* get_testname() {
  return "fir8";
}

#endif

void test_setup() {
  for (int i=0;i<200;i++)
    input[i] = input_l2[i];
  for (int k=0;k<FILTER_SIZE;k++)
    filter[k] = filter_l2[k];
}

void test_clear() {
  for (int i=0;i<200;i++){
    output[i] = 0;
  }
}

void test_run() {
#if DOTP==1
#if WORD==16
  fir16_dotp(input, filter, output, 200, 10);
#else
  fir8_dotp(input, filter, output, 200, 12);
#endif
#else
#if WORD==16
  fir16(input, filter, output, 200, 10);
#else
  fir8(input, filter, output, 200, 12);
#endif
#endif
}

#if WORD==16
int test_check() {
  return crc32(output, 190 * sizeof(int16_t)) == 0x156b4864;
}
#else
int test_check() {
  return crc32(output, 188 * sizeof(int16_t)) == 0xa2f52891;
}
#endif
