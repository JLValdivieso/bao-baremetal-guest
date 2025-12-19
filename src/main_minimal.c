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
#include <spinlock.h>
#include <plat.h>
#include <uart.h>

spinlock_t print_lock = SPINLOCK_INITVAL;

void main(void)
{
    if (cpu_is_master()) {
        spin_lock(&print_lock);
        printf("\n[BAO] Bare-metal guest running on Cheshire\n");
        printf("[BAO] CPU ID: %d\n", get_cpuid());
        spin_unlock(&print_lock);
    }

    /* Keep CPU alive without WFI */
    while (1) {
        asm volatile("");
    }
}
