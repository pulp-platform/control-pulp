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

/* FreeRTOS kernel includes. */
#include <FreeRTOS.h>
#include <task.h>

#include "scmi_protocol.h"

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>

#include "plic.h"
#include "irq.h"

#ifndef NUM_SCMI_MSG
#define NUM_SCMI_MSG 1
#endif

#ifdef DEBUG
#define assert(expression)                                                     \
    do {                                                                       \
        if (!(expression)) {                                                   \
            printf("%s:%d: assert error\n", __FILE__, __LINE__);               \
            exit(1);                                                           \
        }                                                                      \
    } while (0)
#else
#define assert(expression)
#endif

#ifdef DEBUG
#define info(...) printf(__VA_ARGS__)
#else
#define info(...)
#endif

#define START_ADDR 0x20000000  // AXI master start address
#define END_ADDRESS 0x3fffffff // AXI master end address

#define IRQ_POS(pos) 1 << pos
#define MHU_ADDR(pos) 0x20000000 + 0x20 * pos

char *string_copy(char *src, char *dst, uint32_t count)
{
    while (count) {
        --count;
        dst[count] = src[count];
    }
    return dst;
}

void plic_setup_mtvec(void);

/* plic function pointer table for interrupt handlers */
void (*plic_isr_table[PLIC_NUM_INT])(void);

struct scmi_message_header hdr;

void scmi_channel_init(uintptr_t from)
{
    uintptr_t addr                      = from;
    struct scmi_shared_memory_area *ptr = addr;
    ptr = (struct scmi_shared_memory_area *)addr;
    printf("Callee initializes channel as free (status = 1)\n");
    ptr->status = 1;
}

void base_protocol_response(struct scmi_shared_memory_area *scmi_memory,
                            volatile scmi_response_t *response,
                            scmi_revision_info_t *revision)
{

    // We support base protocol only (protocol_id = 0x10)
    switch (scmi_memory->header.id) {
    // PROTOCOL_VERSION
    case 0x0: {
        response->discovery.status   = 0;
        response->discovery.response = 0x20000;
        break;
    }

    // PROTOCOL_ATTRIBUTES
    case 0x1: {
        response->discovery.status   = 0;
        response->discovery.response = 0;
        break;
    }

    // PROTOCOL_MESSAGE_ATTRIBUTES
    case 0x2: {
        break;
    }

    // BASE_DISCOVER_VENDOR
    case 0x3: {
        response->string.status = 0;
        string_copy(revision->vendor_id, response->string.str,
                    SCMI_MAX_STR_SIZE);
        break;
    }

    // BASE_DISCOVER_SUB_VENDOR
    case 0x4: {
        response->string.status = 0;
        string_copy(revision->sub_vendor_id, response->string.str,
                    SCMI_MAX_STR_SIZE);
        break;
    }

    // BASE_DISCOVER_IMPLEMENTATION_VERSION
    case 0x5: {
        response->discovery.status   = 0;
        response->discovery.response = revision->impl_ver; // first version
        break;
    }

    // BASE_DISCOVER_LIST_PROTOCOLS
    case 0x6: {
        response->protocols.status = 0;
        response->protocols.count  = revision->num_protocols;
        break;
    }

        // END OF MANDATORY SUPPORTED MESSAGES
    }
}

void handle_scmi(void* dontcare, uint32_t src)
{
    struct scmi_shared_memory_area *scmi_memory;
    volatile scmi_response_t *response = &(scmi_memory->payload);

    volatile uint32_t *ext_base_addr    = (uint32_t *)(START_ADDR);
    struct scmi_shared_memory_area *ptr = MHU_ADDR(src);

    scmi_revision_info_t *revision;

    if (!ptr->status) {

	info("Callee processes the message; reading the message at %p\n",
	     ptr);
	scmi_memory = ((struct scmi_shared_memory_area *)ptr);

	info("Check caller message and callee message matches\n");
	assert(scmi_memory->header.id == hdr.id);
	assert(scmi_memory->header.type == hdr.type);
	assert(scmi_memory->header.protocol == hdr.protocol);
	assert(scmi_memory->header.token == hdr.token);
	assert(scmi_memory->header.zero == hdr.zero);

	/* Callee updates shared memory area with
	 * return data after message processing in the payload field
	 * according to message_id and protocol_id
	 */

	info("Callee returns response to message\n");

	base_protocol_response(scmi_memory, response, revision);

	info("Callee sets channel free (status = 1)\n");
	ptr->status = 1;
    }
}

#define IRQ_HANDLE_SCMI(SRC)                                                   \
    void irq##SRC##_handle_callee_resp(void)                                   \
    {                                                                          \
        BaseType_t xHigherPriorityTaskWoken = pdFALSE;                         \
        xTimerPendFunctionCallFromISR(handle_scmi, NULL, (uint32_t)SRC,        \
                                      &xHigherPriorityTaskWoken);              \
        portYIELD_FROM_ISR(xHigherPriorityTaskWoken);                          \
    }

/* X-Macro to generate something 147 times for PLIC related stuff */
#define GEN_PLIC_LIST                                                          \
    X(0);                                                                      \
    X(1);                                                                      \
    X(2);                                                                      \
    X(3);                                                                      \
    X(4);                                                                      \
    X(5);                                                                      \
    X(6);                                                                      \
    X(7);                                                                      \
    X(8);                                                                      \
    X(9);                                                                      \
    X(10);                                                                     \
    X(11);                                                                     \
    X(12);                                                                     \
    X(13);                                                                     \
    X(14);                                                                     \
    X(15);                                                                     \
    X(16);                                                                     \
    X(17);                                                                     \
    X(18);                                                                     \
    X(19);                                                                     \
    X(20);                                                                     \
    X(21);                                                                     \
    X(22);                                                                     \
    X(23);                                                                     \
    X(24);                                                                     \
    X(25);                                                                     \
    X(26);                                                                     \
    X(27);                                                                     \
    X(28);                                                                     \
    X(29);                                                                     \
    X(30);                                                                     \
    X(31);                                                                     \
    X(32);                                                                     \
    X(33);                                                                     \
    X(34);                                                                     \
    X(35);                                                                     \
    X(36);                                                                     \
    X(37);                                                                     \
    X(38);                                                                     \
    X(39);                                                                     \
    X(40);                                                                     \
    X(41);                                                                     \
    X(42);                                                                     \
    X(43);                                                                     \
    X(44);                                                                     \
    X(45);                                                                     \
    X(46);                                                                     \
    X(47);                                                                     \
    X(48);                                                                     \
    X(49);                                                                     \
    X(50);                                                                     \
    X(51);                                                                     \
    X(52);                                                                     \
    X(53);                                                                     \
    X(54);                                                                     \
    X(55);                                                                     \
    X(56);                                                                     \
    X(57);                                                                     \
    X(58);                                                                     \
    X(59);                                                                     \
    X(60);                                                                     \
    X(61);                                                                     \
    X(62);                                                                     \
    X(63);                                                                     \
    X(64);                                                                     \
    X(65);                                                                     \
    X(66);                                                                     \
    X(67);                                                                     \
    X(68);                                                                     \
    X(69);                                                                     \
    X(70);                                                                     \
    X(71);                                                                     \
    X(72);                                                                     \
    X(73);                                                                     \
    X(74);                                                                     \
    X(75);                                                                     \
    X(76);                                                                     \
    X(77);                                                                     \
    X(78);                                                                     \
    X(79);                                                                     \
    X(80);                                                                     \
    X(81);                                                                     \
    X(82);                                                                     \
    X(83);                                                                     \
    X(84);                                                                     \
    X(85);                                                                     \
    X(86);                                                                     \
    X(87);                                                                     \
    X(88);                                                                     \
    X(89);                                                                     \
    X(90);                                                                     \
    X(91);                                                                     \
    X(92);                                                                     \
    X(93);                                                                     \
    X(94);                                                                     \
    X(95);                                                                     \
    X(96);                                                                     \
    X(97);                                                                     \
    X(98);                                                                     \
    X(99);                                                                     \
    X(100);                                                                    \
    X(101);                                                                    \
    X(102);                                                                    \
    X(103);                                                                    \
    X(104);                                                                    \
    X(105);                                                                    \
    X(106);                                                                    \
    X(107);                                                                    \
    X(108);                                                                    \
    X(109);                                                                    \
    X(110);                                                                    \
    X(111);                                                                    \
    X(112);                                                                    \
    X(113);                                                                    \
    X(114);                                                                    \
    X(115);                                                                    \
    X(116);                                                                    \
    X(117);                                                                    \
    X(118);                                                                    \
    X(119);                                                                    \
    X(120);                                                                    \
    X(121);                                                                    \
    X(122);                                                                    \
    X(123);                                                                    \
    X(124);                                                                    \
    X(125);                                                                    \
    X(126);                                                                    \
    X(127);                                                                    \
    X(128);                                                                    \
    X(129);                                                                    \
    X(130);                                                                    \
    X(131);                                                                    \
    X(132);                                                                    \
    X(133);                                                                    \
    X(134);                                                                    \
    X(135);                                                                    \
    X(136);                                                                    \
    X(137);                                                                    \
    X(138);                                                                    \
    X(139);                                                                    \
    X(140);                                                                    \
    X(141);                                                                    \
    X(142);                                                                    \
    X(143);                                                                    \
    X(144);                                                                    \
    X(145);                                                                    \
    X(146);

/* generate all PLIC SCMI handlers */
#define X IRQ_HANDLE_SCMI
GEN_PLIC_LIST;
#undef X

void scmi_setup(volatile uint32_t *ext_base_addr,
                scmi_revision_info_t revision_info)
{

    printf("Shared memory area size: %d Bytes\n\n",
           sizeof(struct scmi_shared_memory_area));

    printf("Shared memory area structure:\n\n");
    printf("Reserved:        length %x, byte offset %x\n", 0x0, 0x4);
    printf("Channel status:  length %x, byte offset %x\n", 0x4, 0x4);
    printf("Reserved:        length %x, byte offset %x\n", 0x8, 0x8);
    printf("Channel flags:   length %x, byte offset %x\n", 0x4, 0x10);
    printf("Length:          length %x, byte offset %x\n", 0x4, 0x14);
    printf("Message header:  length %x, byte offset %x\n", 0x4, 0x18);
    printf("Message payload: length %x, byte offset %x\n\n", 0x4, 0x1c);

    string_copy("CONTROLPULPTEST", revision_info.vendor_id, SCMI_MAX_STR_SIZE);
    string_copy("CONTROLPULPTEST", revision_info.sub_vendor_id,
                SCMI_MAX_STR_SIZE);
    revision_info.major_ver     = 3;
    revision_info.minor_ver     = 0;
    revision_info.impl_ver      = 1;
    revision_info.num_protocols = 0;
    revision_info.num_agents    = 1;

    printf(
        "Test SCMI protocol: write a message to simulation memory and waiting for an answer\n");
    printf("PMS is the callee\n");
    hdr.id       = 0x0;  // protocol version msg
    hdr.type     = 0x0;  // is a command, type 0
    hdr.protocol = 0x10; // base protocol
    hdr.token    = 0x42;
    hdr.zero     = 0; // zero :)
}

/* Task that just enables the plic interrupt on the clint. We do this so that we
 * let the plic interrupts only fire after we started the freertos scheduler. */
void enable_interrupts(void)
{
    printf("enabling plic interrupt from task\n");
    /* enable interrupt 25 on apb_interrupt_ctrl */
    irq_enable(1 << 25);

    /* enable interrupt 25 on clint */
    unsigned long __val = (1 << 25);
    asm volatile("csrrs %0, mie, %1" : "=r"(__val) : "rK"(__val) : "memory");

    /* freertos tasks may never finish */
    for(;;)
	;
}

/* freertos plic handler */
void plic_handler(void)
{
    uint32_t id = *((uint32_t*)(PLIC_BASE_ADDR + PLIC_CLAIM_OFFSET(0))); /* claim */
    plic_isr_table[id]();
    *((uint32_t*)(PLIC_BASE_ADDR + PLIC_CLAIM_OFFSET(0))) = id; /* complete */
}

int main(void)
{
    /* Init board hardware. */
    system_init();

    volatile uint32_t *ext_base_addr = (uint32_t *)(START_ADDR);
    volatile uint32_t *ext_end_addr =
        ext_base_addr + sizeof(struct scmi_shared_memory_area);

    scmi_revision_info_t revision_info;

    scmi_setup(ext_base_addr, revision_info);

    /* Set up plic handlers. We start counting from one since the zeroth doesn't
     * exist by design */

#define HOOK_IRQ_PLIC(SRC)                                                     \
    plic_isr_table[SRC + 1] = irq##SRC##_handle_callee_resp;

#define X HOOK_IRQ_PLIC
    GEN_PLIC_LIST;
#undef X

    /* TODO: hackish: extend vector table used by freertos */
    extern void (*isr_table[32])(void);
    isr_table[25] = plic_handler; // 25


    BaseType_t xTask;
    TaskHandle_t xHandler0 = NULL;

    xTask = xTaskCreate(enable_interrupts, "int", ((unsigned short)configMINIMAL_STACK_SIZE),
                        NULL, tskIDLE_PRIORITY + 1, &xHandler0);

    if (xTask != pdPASS) {
        printf("creating task failed\n");
        exit(1);
    }

    for (int msg_cnt = 0; msg_cnt < NUM_SCMI_MSG; msg_cnt++) {

        printf("\nMessage #%d\n", msg_cnt);

        uintptr_t addr = ext_base_addr + 0x20 / 4 * msg_cnt;
        int irq_pos    = msg_cnt + 1;

        scmi_channel_init((uintptr_t)addr);

        /* enable plic interrupt */
        writew(IRQ_POS(irq_pos),
               PLIC_BASE_ADDR + PLIC_ENABLE_OFFSET(irq_pos, 0));

        /* raise threshold of interrupt above zero */
        writew(0x1, PLIC_BASE_ADDR + PLIC_PRIORITY_OFFSET(irq_pos));

        /* Caller rings Doorbell. Doorbell should be a register @ caller side
         * that triggers an interrupt We simulate the mechanism through which
         * the irq is raised in SW (here) 72 mailbox_i irqs are mapped to irq25;
         * PMS jumps to the callee response function in the handler Callee
         * response function reads the message, send the return value and mark
         * the channel as free
         */
    }

    printf("starting scheduler\n");
    vTaskStartScheduler();

    printf("Done\n");
    return 0;
}

void vApplicationMallocFailedHook(void)
{
    /* vApplicationMallocFailedHook() will only be called if
    configUSE_MALLOC_FAILED_HOOK is set to 1 in FreeRTOSConfig.h.  It is a hook
    function that will get called if a call to pvPortMalloc() fails.
    pvPortMalloc() is called internally by the kernel whenever a task, queue,
    timer or semaphore is created.  It is also called by various parts of the
    demo application.  If heap_1.c or heap_2.c are used, then the size of the
    heap available to pvPortMalloc() is defined by configTOTAL_HEAP_SIZE in
    FreeRTOSConfig.h, and the xPortGetFreeHeapSize() API function can be used
    to query the size of free heap space that remains (although it does not
    provide information on how the remaining heap might be fragmented). */
    taskDISABLE_INTERRUPTS();
    printf("error: application malloc failed\n");
    __asm volatile("ebreak");
    for (;;)
        ;
}

void vApplicationIdleHook(void)
{
    /* vApplicationIdleHook() will only be called if configUSE_IDLE_HOOK is set
    to 1 in FreeRTOSConfig.h.  It will be called on each iteration of the idle
    task.  It is essential that code added to this hook function never attempts
    to block in any way (for example, call xQueueReceive() with a block time
    specified, or call vTaskDelay()).  If the application makes use of the
    vTaskDelete() API function (as this demo application does) then it is also
    important that vApplicationIdleHook() is permitted to return to its calling
    function, because it is the responsibility of the idle task to clean up
    memory allocated by the kernel to any task that has since been deleted. */
}

void vApplicationStackOverflowHook(TaskHandle_t pxTask, char *pcTaskName)
{
    (void)pcTaskName;
    (void)pxTask;

    /* Run time stack overflow checking is performed if
    configCHECK_FOR_STACK_OVERFLOW is defined to 1 or 2.  This hook
    function is called if a stack overflow is detected. */
    taskDISABLE_INTERRUPTS();
    printf("error: stack overflow\n");
    __asm volatile("ebreak");
    for (;;)
        ;
}

void vApplicationTickHook(void)
{
}
