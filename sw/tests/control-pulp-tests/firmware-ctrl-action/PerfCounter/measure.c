/*
* Copyright 2023 ETH Zurich and University of Bologna
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
*
* SPDX-License-Identifier: Apache-2.0
*/
/***************************************************/
/*
* Library to perform the measurement for the project,
* Using FreeRTOS
*
* Date of creation: 31/05/2019
*
* Date of Last Modification: 31/05/2019
*
*/

#include "measure.h"

#include "cfg_firmware.h"
//#include "gap_common.h"

/*** REG Register Definitions ***/
//These are here instead of in the incude.h because they are Taget-dependent.

#define REG_CYCLE_Pos                 0U                                            /*!< REG: CYCLE Position */
#define REG_CYCLE_Msk                 (0x1UL /*<< REG_CYCLE_Pos*/)                 /*!< REG: CYCLE Mask */

#define REG_INSTR_Pos                 1U                                            /*!< REG: _INSTR Position */
#define REG_INSTR_Msk                 (0x1UL << REG_INSTR_Pos)                     /*!< REG: _INSTR Mask */

//Load Stall
#define REG_LD_STALL_Pos              2U                                            /*!< REG: LD_STALL Position */
#define REG_LD_STALL_Msk              (0x1UL << REG_LD_STALL_Pos)                  /*!< REG: LD_STALL Mask */

//Jump Stall
#define REG_JMP_STALL_Pos             3U                                            /*!< REG: JMP_STALL Position */
#define REG_JMP_STALL_Msk             (0x1UL << REG_JMP_STALL_Pos)                 /*!< REG: JMP_STALL Mask */

//Instructions Missing
//Cycles waiting for instruction fethces, excluding jumps and branches
#define REG_IMISS_Pos                 4U                                            /*!< REG: IMISS Position */
#define REG_IMISS_Msk                 (0x1UL << REG_IMISS_Pos)                     /*!< REG: IMISS Mask */

//#define REG_WBRANCH_Pos               0U                                            /*!< REG: WBRANCH Position */
//#define REG_WBRANCH_Msk               (0x1UL << REG_WBRANCH_Pos)                   /*!< REG: WBRANCH Mask */

//#define REG_WBRANCH_CYC_Pos           0U                                            /*!< REG: WBRANCH_CYC Position */
//#define REG_WBRANCH_CYC_Msk           (0x1UL << REG_WBRANCH_CYC_Pos)               /*!< REG: WBRANCH_CYC Mask */

//Number of load instructions
#define REG_LD_Pos                    5U                                            /*!< REG: LD Position */
#define REG_LD_Msk                    (0x1UL << REG_LD_Pos)                        /*!< REG: LD Mask */

//Number of store instructions
#define REG_ST_Pos                    6U                                            /*!< REG: ST Position */
#define REG_ST_Msk                    (0x1UL << REG_ST_Pos)                        /*!< REG: ST Mask */

//Number of jumps (unconditional)
#define REG_JUMP_Pos                  7U                                            /*!< REG: JUMP Position */
#define REG_JUMP_Msk                  (0x1UL << REG_JUMP_Pos)                      /*!< REG: JUMP Mask */

//Number of branches (conditional)
#define REG_BRANCH_Pos                8U                                           /*!< REG: BRANCH Position */
#define REG_BRANCH_Msk                (0x1UL << REG_BRANCH_Pos)                    /*!< REG: BRANCH Mask */

//#define REG_DELAY_SLOT_Pos            11U                                           /*!< REG: DELAY_SLOT Position */
//#define REG_DELAY_SLOT_Msk            (0x1UL << REG_DELAY_SLOT_Pos)                /*!< REG: DELAY_SLOT Mask */

//#define REG_LD_EXT_Pos                12U                                           /*!< REG: LD_EXT Position */
//#define REG_LD_EXT_Msk                (0x1UL << REG_LD_EXT_Pos)                    /*!< REG: LD_EXT Mask */

//#define REG_ST_EXT_Pos                13U                                           /*!< REG: ST_EXT Position */
//#define REG_ST_EXT_Msk                (0x1UL << REG_ST_EXT_Pos)                    /*!< REG: ST_EXT Mask */

//#define REG_LD_EXT_CYC_Pos            14U                                           /*!< REG: LD_EXT_CYC Position */
//#define REG_LD_EXT_CYC_Msk            (0x1UL << REG_LD_EXT_CYC_Pos)                /*!< REG: LD_EXT_CYC Mask */

//#define REG_ST_EXT_CYC_Pos            15U                                           /*!< REG: ST_EXT_CYC Position */
//#define REG_ST_EXT_CYC_Msk            (0x1UL << REG_ST_EXT_CYC_Pos)                /*!< REG: ST_EXT_CYC Mask */

//#define REG_TCDM_CONT_Pos             16U                                           /*!< REG: TCDM_CONT Position */
//#define REG_TCDM_CONT_Msk             (0x1UL << REG_TCDM_CONT_Pos)                 /*!< REG: TCDM_CONT Mask */

//#define REG_EVENTS_NUM                17U                                           /*!< REG: All events number */

//Number of branches taken (conditional)
#define REG_BRANCH_TAKEN_Pos            9U
#define REG_BRANCH_TAKEN_Msk            (0x1UL << REG_BRANCH_TAKEN_Pos)

//Number of compressed instructions retired
#define REG_COMP_INSTR_Pos              10U
#define REG_COMP_INSTR_Msk              (0x1UL << REG_COMP_INSTR_Pos)

//Cycles from stalled pipeline
#define REG_PIPE_STALL_Pos              11U
#define REG_PIPE_STALL_Msk              (0x1UL << REG_PIPE_STALL_Pos)

//Number of type conflicts on APU/FP
#define REG_APU_TYPE_Pos                12U
#define REG_APU_TYPE_Msk                (0x1UL << REG_APU_TYPE_Pos)

//Number of contentions on APU/FP
#define REG_APU_CONT_Pos                13U
#define REG_APU_CONT_Msk                (0x1UL << REG_APU_CONT_Pos)

//Number of dependency stall on APU/FP
#define REG_APU_DEP_Pos                 14U
#define REG_APU_DEP_Msk                 (0x1UL << REG_APU_DEP_Pos)

//Number of write backs on APUB/FP
#define REG_APU_WB_Pos                  15U
#define REG_APU_WB_Msk                  (0x1UL << REG_APU_WB_Pos)



// Enable/Reset
#define CSR_MCOUNTINHIBIT_ACTIVE       0x0
#define CSR_MCOUNTINHIBIT_RESET        0xfffffffd

// Addresses mapping
//#define CSR_MCYCLE            0xB00
//#define CSR_MINSTRET          0xB02
#define CSR_REGCOUNTER(N)       (0xB03 + (N))
#define CSR_MCOUNTINHIBIT       0x320          // Event Selector
#define CSR_REGEVENT(M)         (0x323 + (M))

// Define asm volatile macros
#define CSR_CONVERT(x)      #x
#define CSR_WRITE(x, var)   asm volatile ("csrw "CSR_CONVERT(x)", %0" :: "r" (var))
#define CSR_READ(x, var)    asm volatile ("csrr %0, "CSR_CONVERT(x)"" : "=r" (var) :)

/*** End ***/

#if (MEASURE_ACTIVE == 1)
int lPerformanceCheck = 0;
int CSCheck = 0;
int Timerindex = 0;
Timer_Data_t timerBuffer[MEASURE_N_OUTPUTS*MEASURE_N_ITERATION+7] = { {'0', 0} };
#endif
/*******************************/
#if (MEASURE_ACTIVE == 2)
uint32_t g_I_cycle_prev = 0;
uint32_t g_cycle_valid_comparison = 0;
uint32_t g_mes_comp_value = 1;
#endif

/***********************/
/*****************************************/
/***********************/
void vMeasureInit ( measure_type_e type )
{
    uint32_t maskConfig = 0x0;

    /* Reset all to 0 */
    CSR_WRITE(CSR_MCOUNTINHIBIT, CSR_MCOUNTINHIBIT_RESET);

    /** Configure  & Enable event: REG register **/
    /* Here, to configure, we need to provide static define values
    * also each event can be associated to 1 perf counter (CSR_REGEVENT(0), CSR_REGEVENT(1), etc.)
    * in the rtl and fpga design, we have 16/32 events, but in the release (aka asic)
    * there will be only 1 */

    if ((type & mCycles) == mCycles)
    {
        maskConfig |= (REG_CYCLE_Msk);
        CSR_WRITE(CSR_REGEVENT(0),  (REG_CYCLE_Msk) );
    }
    if ((type & mInstr) == mInstr)
    {
        maskConfig |= (REG_INSTR_Msk);
        CSR_WRITE(CSR_REGEVENT(1),  (REG_INSTR_Msk) );
    }
    if ((type & mLoad) == mLoad)
    {
        maskConfig |= (REG_LD_Msk);
        CSR_WRITE(CSR_REGEVENT(5),  (REG_LD_Msk) );
    }
    if ((type & mStore) == mStore)
    {
        maskConfig |= (REG_ST_Msk);
        CSR_WRITE(CSR_REGEVENT(6),  (REG_ST_Msk) );
    }
    if ((type & mJump) == mJump)
    {
        maskConfig |= (REG_JUMP_Msk);
        CSR_WRITE(CSR_REGEVENT(7),  (REG_JUMP_Msk) );
    }
    if ((type & mBranch) == mBranch)
    {
        maskConfig |= (REG_BRANCH_Msk);
        CSR_WRITE(CSR_REGEVENT(8),  (REG_BRANCH_Msk) );
    }
    if ((type & mCInstr) == mCInstr)
    {
        maskConfig |= (REG_COMP_INSTR_Msk);
        CSR_WRITE(CSR_REGEVENT(10),  (REG_COMP_INSTR_Msk) );
    }

    //

    if ((type & mLdStall) == mLdStall)
    {
        maskConfig |= (REG_LD_STALL_Msk);
        CSR_WRITE(CSR_REGEVENT(2),  (REG_LD_STALL_Msk) );
    }
    if ((type & mStStall) == mStStall)
    {
        //nothing
    }
    if ((type & mInstrMiss) == mInstrMiss)
    {
        maskConfig |= (REG_IMISS_Msk);
        CSR_WRITE(CSR_REGEVENT(4),  (REG_IMISS_Msk) );
    }
    if ((type & mJmpStall) == mJmpStall)
    {
        maskConfig |= (REG_JMP_STALL_Msk);
        CSR_WRITE(CSR_REGEVENT(3),  (REG_JMP_STALL_Msk) );
    }
    if ((type & mBrchTaken) == mBrchTaken)
    {
        maskConfig |= (REG_BRANCH_TAKEN_Msk);
        CSR_WRITE(CSR_REGEVENT(9),  (REG_BRANCH_TAKEN_Msk) );
    }
    if ((type & mPipeStall) == mPipeStall)
    {
        maskConfig |= (REG_PIPE_STALL_Msk);
        CSR_WRITE(CSR_REGEVENT(11),  (REG_PIPE_STALL_Msk) );
    }
    if ((type & mApuDependStall) == mApuDependStall)
    {
        maskConfig |= (REG_APU_DEP_Msk);
        CSR_WRITE(CSR_REGEVENT(14),  (REG_APU_DEP_Msk) );
    }

    //

    if ((type & mApuTypeConfl) == mApuTypeConfl)
    {
        maskConfig |= (REG_APU_TYPE_Msk);
        CSR_WRITE(CSR_REGEVENT(12),  (REG_APU_TYPE_Msk) );
    }
    if ((type & mApuContention) == mApuContention)
    {
        maskConfig |= (REG_APU_CONT_Msk);
        CSR_WRITE(CSR_REGEVENT(13),  (REG_APU_CONT_Msk) );
    }
    if ((type & mApuWriteBack) == mApuWriteBack)
    {
        maskConfig |= (REG_APU_WB_Msk);
        CSR_WRITE(CSR_REGEVENT(15),  (REG_APU_WB_Msk) );
    }
}

void vMeasureStart (void)
{
    /* Enable counters: */
    CSR_WRITE(CSR_MCOUNTINHIBIT, CSR_MCOUNTINHIBIT_ACTIVE);
}
void vMeasureStop (void)
{
    //TODO
}

//TODO: need to implement zeroing for all the functions below
inline uint32_t lMeasureReadCsr(int zeroing) // __attribute__((always_inline))
{
    uint32_t result;
    // This function does not work because compiler cannot "convert" the csr_num to a 12-bit Immediate.
    //asm("csrr %0, %1" : "=r"(result) : "I"(csr_num.value));

    CSR_READ(CSR_REGCOUNTER(MEASURE_CSR), result);

    return result;
}

inline uint32_t lMeasureReadCycle ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* Cycles */
    CSR_READ(CSR_REGCOUNTER(0),  value);

    return value;
}
inline uint32_t lMeasureReadInstr ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* Instructions */
    CSR_READ(CSR_REGCOUNTER(1),  value);

    return value;
}
inline uint32_t lMeasureReadLdStall ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* LD stall */
    CSR_READ(CSR_REGCOUNTER(2),  value);

    return value;
}
inline uint32_t lMeasureReadInstrMiss ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* Istr Stall */
    CSR_READ(CSR_REGCOUNTER(4),  value);

    return value;
}
inline uint32_t lMeasureReadLoad ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* LD */
    CSR_READ(CSR_REGCOUNTER(5),  value);

    return value;
}
inline uint32_t lMeasureReadStore ( int zeroing )
{
    /* Read */
    uint32_t value = 0;
    /* Store */
    CSR_READ(CSR_REGCOUNTER(6),  value);

    return value;
}
