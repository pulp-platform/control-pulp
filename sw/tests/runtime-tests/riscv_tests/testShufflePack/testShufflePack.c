// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#include <stdio.h>
#include "pulp.h"

#include "testShufflePack_stimuli.h"

#define SHUFFLE_H        "pv.shuffle.h"
#define SHUFFLE_H_SCI    "pv.shuffle.sci.h"
#define SHUFFLE_B        "pv.shuffle.b"
#define SHUFFLEI0_B_SCI  "pv.shuffleI0.sci.b"
#define SHUFFLEI1_B_SCI  "pv.shuffleI1.sci.b"
#define SHUFFLEI2_B_SCI  "pv.shuffleI2.sci.b"
#define SHUFFLEI3_B_SCI  "pv.shuffleI3.sci.b"
#define SHUFFLE2_H       "pv.shuffle2.h"
#define SHUFFLE2_B       "pv.shuffle2.b"
#define PACK_H_SC        "pv.pack"
#define PACKHI_B_SC      "pv.packhi.b"
#define PACKLO_B_SC      "pv.packlo.b"

void check_shuffle_h        (testresult_t *result, void (*start)(), void (*stop) () );
void check_shuffle_b        (testresult_t *result, void (*start)(), void (*stop) () );
void check_shuffle2_h       (testresult_t *result, void (*start)(), void (*stop) () );
void check_shuffle2_b       (testresult_t *result, void (*start)(), void (*stop) () );
void check_pack_h           (testresult_t *result, void (*start)(), void (*stop) () );
void check_pack_hi_b        (testresult_t *result, void (*start)(), void (*stop) () );
void check_pack_lo_b        (testresult_t *result, void (*start)(), void (*stop) () );

testcase_t testcases[] = {
  { .name = "shuffle_h"       , .test = check_shuffle_h       },
  { .name = "shuffle_b"       , .test = check_shuffle_b       },
  { .name = "shuffle2_h"      , .test = check_shuffle2_h      },
  { .name = "shuffle2_b"      , .test = check_shuffle2_b      },
  { .name = "pack_h"          , .test = check_pack_h          },
  { .name = "pack_hi_b"       , .test = check_pack_hi_b       },
  { .name = "pack_lo_b"       , .test = check_pack_lo_b       },
  {0, 0}
};

#define shuffle_b_sci(arg_a, arg_b, arg_exp) \
  if ((arg_b >> 6) == 0) { \
    asm volatile (SHUFFLEI0_B_SCI " %[c], %[a], %[imm]\n" \
      : [c] "+r" (res) \
      : [a] "r"  (arg_a), [imm] "i" (arg_b)); \
    check_uint32(result, "shuffle_b", res, arg_exp); \
  } else if ((arg_b >> 6) == 1) { \
    asm volatile (SHUFFLEI1_B_SCI " %[c], %[a], %[imm]\n" \
      : [c] "+r" (res) \
      : [a] "r"  (arg_a), [imm] "i" (arg_b)); \
    check_uint32(result, "shuffle_b", res, arg_exp); \
  } else if ((arg_b >> 6) == 2) { \
    asm volatile (SHUFFLEI2_B_SCI " %[c], %[a], %[imm]\n" \
      : [c] "+r" (res) \
      : [a] "r"  (arg_a), [imm] "i" (arg_b)); \
    check_uint32(result, "shuffle_b", res, arg_exp); \
  } else { \
    asm volatile (SHUFFLEI3_B_SCI " %[c], %[a], %[imm]\n" \
      : [c] "+r" (res) \
      : [a] "r"  (arg_a), [imm] "i" (arg_b)); \
    check_uint32(result, "shuffle_b", res, arg_exp); \
  }

int main()
{
#ifdef USE_CLUSTER
  if (rt_cluster_id() != 0)
    return bench_cluster_forward(0);
#endif

  int retval = 0;

  if(get_core_id() == 0) {
    retval = run_suite(testcases);
  }

  return retval;
}


//################################################################################
//#  test shuffle
//################################################################################

void check_shuffle_h(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int res = 0, i;

  //-----------------------------------------------------------------
  // Check pv.shuffle.*.h
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (SHUFFLE_H " %[c], %[a], %[b]\n"
                  : [c] "=r" (res)
                  : [a] "r"  (g_shuffle_h_a[i]), [b] "r" (g_shuffle_h_b[i]));

    check_uint32(result, "shuffle_h", res, g_shuffle_h_exp[i]);
  }

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
             : [c] "+r" (res)
             : [a] "r"  (g_shuffle_sci_h_a[0]), [imm] "i" (g_shuffle_sci_h_0));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[0]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[1]), [imm] "i" (g_shuffle_sci_h_1));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[1]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[2]), [imm] "i" (g_shuffle_sci_h_2));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[2]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[3]), [imm] "i" (g_shuffle_sci_h_3));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[3]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[4]), [imm] "i" (g_shuffle_sci_h_4));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[4]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[5]), [imm] "i" (g_shuffle_sci_h_5));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[5]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[6]), [imm] "i" (g_shuffle_sci_h_6));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[6]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[7]), [imm] "i" (g_shuffle_sci_h_7));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[7]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[8]), [imm] "i" (g_shuffle_sci_h_8));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[8]);

  asm volatile (SHUFFLE_H_SCI " %[c], %[a], %[imm]\n"
              : [c] "+r" (res)
              : [a] "r"  (g_shuffle_sci_h_a[9]), [imm] "i" (g_shuffle_sci_h_9));

  check_uint32(result, "shuffle_h", res, g_shuffle_sci_h_exp[9]);
}

void check_shuffle_b(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int res=0,i;

  //-----------------------------------------------------------------
  // Check pv.shuffle.*.b
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (SHUFFLE_B " %[c], %[a], %[b]\n"
                  : [c] "+r" (res)
                  : [a] "r"  (g_shuffle_b_a[i]), [b] "r" (g_shuffle_b_b[i]));

    check_uint32(result, "shuffle_b", res, g_shuffle_b_exp[i]);
  }

  shuffle_b_sci(g_shuffle_sci_b_a[0], g_shuffle_sci_b_0, g_shuffle_sci_b_exp[0])
  shuffle_b_sci(g_shuffle_sci_b_a[1], g_shuffle_sci_b_1, g_shuffle_sci_b_exp[1])
  shuffle_b_sci(g_shuffle_sci_b_a[2], g_shuffle_sci_b_2, g_shuffle_sci_b_exp[2])
  shuffle_b_sci(g_shuffle_sci_b_a[3], g_shuffle_sci_b_3, g_shuffle_sci_b_exp[3])
  shuffle_b_sci(g_shuffle_sci_b_a[4], g_shuffle_sci_b_4, g_shuffle_sci_b_exp[4])
  shuffle_b_sci(g_shuffle_sci_b_a[5], g_shuffle_sci_b_5, g_shuffle_sci_b_exp[5])
  shuffle_b_sci(g_shuffle_sci_b_a[6], g_shuffle_sci_b_6, g_shuffle_sci_b_exp[6])
  shuffle_b_sci(g_shuffle_sci_b_a[7], g_shuffle_sci_b_7, g_shuffle_sci_b_exp[7])
  shuffle_b_sci(g_shuffle_sci_b_a[8], g_shuffle_sci_b_8, g_shuffle_sci_b_exp[8])
  shuffle_b_sci(g_shuffle_sci_b_a[9], g_shuffle_sci_b_9, g_shuffle_sci_b_exp[9])
}

//################################################################################
//#  test lv32.shuffle2
//################################################################################

void check_shuffle2_h(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int i;

  //-----------------------------------------------------------------
  // Check pv.shuffle2.*.h
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (SHUFFLE2_H " %[c], %[a], %[b]\n"
                  : [c] "+r" (g_shuffle2_h_c[i])
                  : [a] "r"  (g_shuffle2_h_a[i]), [b] "r" (g_shuffle2_h_b[i]));

    check_uint32(result, "shuffle2_h", g_shuffle2_h_c[i], g_shuffle2_h_exp[i]);
  }
}

void check_shuffle2_b(testresult_t *result, void (*start)(), void (*stop) () ){
  unsigned int i;

  //-----------------------------------------------------------------
  // Check pv.shuffle2.*.b
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (SHUFFLE2_B " %[c], %[a], %[b]\n"
                  : [c] "+r" (g_shuffle2_b_c[i])
                  : [a] "r"  (g_shuffle2_b_a[i]), [b] "r" (g_shuffle2_b_b[i]));

    check_uint32(result, "shuffle2_b", g_shuffle2_b_c[i], g_shuffle2_b_exp[i]);
 }
}

void check_pack_h(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int i,res = 0;

  //-----------------------------------------------------------------
  // Check pv.pack
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (PACK_H_SC " %[c], %[a], %[b]\n"
                  : [c] "+r" (res)
                  : [a] "r"  (g_pack_h_a[i]), [b] "r" (g_pack_h_b[i]));

    check_uint32(result, "pack_h", res, g_pack_h_exp[i]);
  }
}

void check_pack_hi_b(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int i;

  //-----------------------------------------------------------------
  // Check pv.packhi.b
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {

    asm volatile (PACKHI_B_SC " %[c], %[a], %[b]\n"
                  : [c] "+r" (g_pack_hi_b_c[i])
                  : [a] "r"  (g_pack_hi_b_a[i]), [b] "r" (g_pack_hi_b_b[i]));

    check_uint32(result, "pack_hi_b", g_pack_hi_b_c[i], g_pack_hi_b_exp[i]);
  }
}

void check_pack_lo_b(testresult_t *result, void (*start)(), void (*stop) ()) {
  unsigned int i;

  //-----------------------------------------------------------------
  // Check pv.packlo.b
  //-----------------------------------------------------------------
  for(i = 0; i < NumberOfStimuli; i++) {
    asm volatile (PACKLO_B_SC " %[c], %[a], %[b]\n"
                  : [c] "+r" (g_pack_lo_b_c[i])
                  : [a] "r"  (g_pack_lo_b_a[i]), [b] "r" (g_pack_lo_b_b[i]));

    check_uint32(result, "pack_lo_b", g_pack_lo_b_c[i], g_pack_lo_b_exp[i]);
  }
}
