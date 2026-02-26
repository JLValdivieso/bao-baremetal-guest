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
#include <string.h> 
#include <cpu.h>
#include <plat.h>
#include <uart.h>

int main(){

    int a = 14;
    int b = 32;

    printf("Hello BAO in a dual configuration\r\n");
    printf("This code is running in a baremetal guest environment with one core\r\n");
    printf("The following operations are performed:\r\n");
    printf("A = %d, B = %d\r\n", a, b);
    printf("The sum is: %d\r\n", a + b);
    printf("The substraction is: %d\r\n", a - b);
    printf("The division is: %f\r\n", (float)a / b);
    printf("End of the test. \r\n");
    
    return 0;
}
