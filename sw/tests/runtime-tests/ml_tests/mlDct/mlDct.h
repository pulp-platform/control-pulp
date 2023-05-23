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
 * Mantainer: Luca Valente luca.valente2@unibo.it
 */
#ifndef __ML_DCT_H__
#define __ML_DCT_H__

/////////////////////////////////////////////////////////
// defines
/////////////////////////////////////////////////////////

// include the shared header for ml kernels
#include "mlShared.h"

/////////////////////////////////////////////////////////
// subfunctions
/////////////////////////////////////////////////////////
/* Type Definitions */
#ifndef struct_dsp_DCT_1
#define struct_dsp_DCT_1

struct dsp_DCT_1
{
  int S0_isInitialized;
  int W0_IDXWKSPACE[32];
  float P0_ScaleFactor;
};

#endif                                 /*struct_dsp_DCT_1*/

#ifndef typedef_dsp_DCT_1
#define typedef_dsp_DCT_1

typedef struct dsp_DCT_1 dsp_DCT_1;

#endif                                 /*typedef_dsp_DCT_1*/

#ifndef typedef_dspcodegen_DCT
#define typedef_dspcodegen_DCT

typedef struct {
  int isInitialized;
  dsp_DCT_1 cSFunObject;
} dspcodegen_DCT;

#endif                                 /*typedef_dspcodegen_DCT*/

/* Function Declarations */
void MWDSPCG_BitReverseData_YD(float y[], const int N, const int stride, const int startIdx);
void MWDSPCG_Dct16Plus_YD_Trig(float y[], const int elem[], int N);
void MWDSPCG_Dct8_YD_Trig(float y[], const int elem[]);
void MWDSPCG_IntroduceStride(int elem[], const int N, const int stride, int elemIdx);
int div_s32_floor(int numerator, int denominator);

/////////////////////////////////////////////////////////
// main testing function 
/////////////////////////////////////////////////////////
int main(int argc, const char * const argv[]);




#endif

