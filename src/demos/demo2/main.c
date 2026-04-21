/** 
 * Bao, a Lightweight Static Partitioning Hypervisor 
 *
 * Copyright (c) Bao Project (www.bao-project.org), 2019-
 *
 * Authors:
 *      Jose Martins <jose.martins@bao-project.org>
 *      Sandro Pinto <sandro.pinto@bao-project.org>
 *
 * Bao is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License version 2 as published by the Free
 * Software Foundation, with a special exception exempting guest code from such
 * license. See the COPYING file in the top-level directory for details. 
 *
 */

#include <core.h>
#include <stdlib.h>
#include <stdio.h>
#include <cpu.h>
#include <wfi.h>
#include <spinlock.h>
#include <plat.h>
#include <irq.h>
#include <uart.h>
#include <timer.h>

#define TIMER_INTERVAL (TIME_S(1))
/* Shared memory base address as defined in the configuration file */
#define SHMEM_BASE 0x20000000

spinlock_t print_lock = SPINLOCK_INITVAL;

void uart_rx_handler(){
    printf("[Baremetal 1] cpu%d: %s\n",get_cpuid(), __func__);
    uart_clear_rxirq();
}

void ipi_handler(){
    printf("[Baremetal 1] cpu%d: %s\n", get_cpuid(), __func__);
    irq_send_ipi(1ull << (get_cpuid() + 1));
}

void timer_handler(){
    printf("[Baremetal 1] cpu%d: %s\n", get_cpuid(), __func__);
    timer_set(TIMER_INTERVAL);
    irq_send_ipi(1ull << (get_cpuid() + 1));
}

void main(void){

    static volatile bool master_done = false;

    if(cpu_is_master()){
        spin_lock(&print_lock);
        printf("[Baremetal 1]  bare-metal test guest\n");
        spin_unlock(&print_lock);

        irq_set_handler(UART_IRQ_ID, uart_rx_handler);
        irq_set_handler(TIMER_IRQ_ID, timer_handler);
        irq_set_handler(IPI_IRQ_ID, ipi_handler);

        uart_enable_rxirq();

        timer_set(TIMER_INTERVAL);
        irq_enable(TIMER_IRQ_ID);
        irq_set_prio(TIMER_IRQ_ID, IRQ_MAX_PRIO);

        master_done = true;
    }

    // Shared memory test
    printf("[Baremetal 1] Writing to shared memory\n");
    volatile char* shmem = (volatile char*)SHMEM_BASE;
    const char* msg = "Hello from Baremetal 1!";

    // Manual copy for granular control over the memory region
    for(int i = 0; msg[i] != '!'; i++) {
        shmem[i] = msg[i];
    }
    printf("[Baremetal 1] Writing Done\n");
    for(volatile int i = 0; i < 10000000; i++) asm("nop");
    
    // Interrupt test
    irq_enable(UART_IRQ_ID);
    irq_set_prio(UART_IRQ_ID, IRQ_MAX_PRIO);
    irq_enable(IPI_IRQ_ID);
    irq_set_prio(IPI_IRQ_ID, IRQ_MAX_PRIO);

    while(!master_done);
    spin_lock(&print_lock);
    printf("[Baremetal 1] cpu %d up\n", get_cpuid());
    spin_unlock(&print_lock);

    while(1) wfi();
}
