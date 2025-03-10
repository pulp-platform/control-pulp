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

#ifndef __HAL_CHIPS_CONTROL_PULP_H__
#define __HAL_CHIPS_CONTROL_PULP_H__

// cv32e40p-specific
#include "hal/cv32e40p/cv32e40p.h"

#include "hal/eu/eu_v3.h"
#include "hal/itc/itc_v1.h"
#if MCHAN_VERSION == 7
#include "hal/dma/mchan_v7.h"
#endif
#if IDMA_VERSION == 1
#include "hal/dma/idma_v1_cl.h"
#include "hal/dma/idma_v1_fc.h"
#endif
#include "hal/timer/timer_v2.h"
#include "hal/soc_eu/soc_eu_v2.h"
#include "hal/cluster_ctrl/cluster_ctrl_v2.h"
#include "hal/icache/icache_ctrl_v2.h"
#include "hal/apb_soc/apb_soc_v3.h"
#include "hal/fll/fll_v1.h"
#include "hal/gpio/gpio_v3.h"
#include "hal/rom/rom_v2.h"

#include "hal/udma/udma_v3.h"
#include "hal/udma/i2c/udma_i2c_v2.h"
#include "hal/udma/spim/udma_spim_v3.h"
#include "hal/udma/uart/udma_uart_v1.h"


#endif
