/********************************************************/
/*
* File: cfg_types.h
* Notes: This file holds the general data type, struct and
*           enum.
*
* Written by: Eventine (UNIBO)
*
*********************************************************/

#ifndef _CFG_TYPES_H_
#define _CFG_TYPES_H_

/* Libraries Inclusion */

/* Others */
#include <stdint.h>

//#define CONTROL_DATA_TYPE     1

/*******************/
/*** Data Types ****/
/*******************/

//TODO: These below are Target-dependent!!

// varBool_e
typedef enum
{
    PCF_FALSE                 = 0x0,	 // False / Inactive / No
    PCF_TRUE                  = 0x1 // True / Active / Yes
} varBool_e;

// varValue
#if (CONTROL_DATA_TYPE == 1)    //float
typedef float 	varValue;
#elif (CONTROL_DATA_TYPE == 2)  //float16
//typedef float16 varValue;
#elif (CONTROL_DATA_TYPE == 3)  //fixed int
//typedef ... varValue;
#else
typedef int 	varValue;
#endif

// varFor
typedef int 	varFor;

// varShInt
//typedef int 	varShortInt;

// varShUnsInt
//typedef uint32_t 	varShortUInt;

// varCounter
typedef int32_t 	varCounter;

// varShCounter
typedef int16_t 	varShortCounter;

// varError
typedef uint32_t    varError;

// varFreqRedMap
typedef uint16_t    varFreqRedMap;

typedef uint32_t    varCoreBinding;



/* Enum */
typedef enum
{
    CTRL_EMPTY,

    CTRL_CONFIG_PARAM,
    CTRL_THERMAL_PARAM,
    CTRL_POWER_PARAM,
    CTRL_INPUT_PARAM,
    CTRL_OUTPUT_PARAM,
    CTRL_IDENT_PARAM,

    CTRL_CONFIG_TABLE,

    CTRL_COMMANDS,

    CTRL_TEMP_MEASURES,
    CTRL_POWER_MEASURES,
    CTRL_PERF_MEASURES,

    CTRL_MEASURES,

    CTRL_INPUT_PROCESS,
    CTRL_MOVING_AVERAGE,
    CTRL_THERMAL,
    CTRL_OUTPUT,

    CTRL_VALUE_TABLE,

    //TODO atm we don't know
    CTRL_TLEMETRY
} pcf_ctrl_struct_e;

typedef enum
{
    GLOBAL_WRITE_NOTHING,
    GLOBAL_WRITE_ALL,
    //
    GLOBAL_WRITE_TARGET_FREQ,
    GLOBAL_WRITE_TOTAL_POWER_BUDGET,
    GLOBAL_WRITE_QUADRANT_POWER_BUDGET,
    GLOBAL_WRITE_CORE_BINDING_VECTOR,
    GLOBAL_WRITE_PERC_WORKLOAD,
    GLOBAL_WRITE_POWER_FORMULA_COEFF
} global_var_write_cmd_e;

//TODO
#define VV_MOVING_AVERAGE 3
#define VV_COUPLING_SOLUTION 4


/*******************/
/*** Enum Struct ***/
/*******************/
enum pcf_tasks_e
{
    /** ATTENTION! **/
    /* Put first the periodic tasks, and after the non-periodic tasks */
    /* First of the periodi task is PERIODIC_CONTROL_TASK */
    //TBD: is this safe enough????

    //Periodic Tasks
    PERIODIC_CONTROL_TASK,
    REAR_CONTROL_TASK,
    FAST_CONTROL_TASK,
    COMMS_TASK,
    MAIN_TASK,
    USER_DEFINED_TASK,

    //Non-Periodic Tasks
    #if (defined(DEBUG_ACTIVE) || (MEASURE_ACTIVE == 1))
    DEBUG_TASK
    #endif
};


/***************************************/
/*** Defined Values ***/

//TBC: should I put 0xFFFFFFFF?
//#define VAR_VALUE_BYTES_NUM 4

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_100_PERC 100.0f
#else
#define VD_100_PERC 100
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_ZERO 0.0f
#else
#define VD_ZERO 0
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_ONE 1.0f
#else
#define VD_ONE 1
#endif

#if ((CONTROL_DATA_TYPE == 1) || (CONTROL_DATA_TYPE == 2))
#define VD_TEMP_INIT 300.0f
#else
#define VD_TEMP_INIT 300
#endif


#endif //lib #ifdef

