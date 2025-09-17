#ifndef CPU_H
#define CPU_H

#include <core.h>

extern int primary_hart;

static inline unsigned long get_cpuid(){
    void* hartid;
    __asm__ volatile("cmove %0, ctp" : "=C"(hartid));
    return (unsigned long) __builtin_cheri_address_get(hartid);
}

static inline bool cpu_is_master(){
    return get_cpuid() == primary_hart;
}

#endif
