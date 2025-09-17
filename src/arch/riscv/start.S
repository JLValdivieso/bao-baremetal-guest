#include <csrs.h>
#define STACK_SIZE  0x4000

/* Load address */
.macro LOAD_ADDR rd, sym
#ifdef __CHERI_PURE_CAPABILITY__
    /* Early boot we need to use the PCC capability*/
    cllc c\rd, \sym
#else
    la   \rd, \sym
#endif
.endm
/* Load XLEN-sized load, with CHERI capabilities or not  */
.macro LOAD rd, off, rs1
#ifdef __CHERI_PURE_CAPABILITY__
  #if __riscv_xlen == 64
    cld \rd, \off(c\rs1)
  #else
    clw \rd, \off(c\rs1)
  #endif
#else
  #if __riscv_xlen == 64
    ld  \rd, \off(\rs1)
  #else
    lw  \rd, \off(\rs1)
  #endif
#endif
.endm

/* Load XLEN-sized store, with CHERI capabilities or not  */

.macro STORE rs2, off, rs1
#ifdef __CHERI_PURE_CAPABILITY__
  #if __riscv_xlen == 64
    csd \rs2, \off(c\rs1)
  #else
    csw \rs2, \off(c\rs1)
  #endif
#else
  #if __riscv_xlen == 64
    sd  \rs2, \off(\rs1)
  #else
    sw  \rs2, \off(\rs1)
  #endif
#endif
.endm

.section ".start", "ax"
.global _start
.type   _start, @function
_start:
    /**
     * Force enter in cap mode if not already in it.
     * This is needed to ensure that the boot code runs in cap mode.
     */
    #ifdef __CHERI_PURE_CAPABILITY__
    .option push
    .option nocapmode
        cspecialr ct0, pcc
        li t1, 1
        csetflags ct0, ct0, t1
        lla t1, 1f
        csetaddr ct0, ct0, t1
    #ifdef __riscv_xcheri_mode_dependent_jumps
        jr.cap ct0
    #else
        cjr ct0
    #endif
    1:
    .option pop
    #endif
    /**
     * Expecting hart id in a0.
     * Save hart id in thread pointer. We assume the compiler does not use tp.
     */
    #ifdef __CHERI_PURE_CAPABILITY__
        cmove ctp, ca0
        cmove cgp, cnull
    #else
        mv      tp, a0
        .option push
        .option norelax
        la  gp, __global_pointer$
        .option pop
    #endif

.pushsection .data
.align 3
.globl primary_hart
.type  primary_hart, @object
.size  primary_hart, 8
primary_hart: .word 0x0
.globl primary_hart_valid
.type  primary_hart_valid, @object
.size  primary_hart_valid, 8
primary_hart_valid: .word 0x0
.popsection

    /* Initialize stack pointer*/
    LOAD_ADDR  t0, _stack_base
    li      t1, STACK_SIZE
#if __CHERI_PURE_CAPABILITY__
    cspecialr   ct2, ddc
    cfromptr    csp, ct2, t0
#ifndef SINGLE_CORE
    mul     t3, t1, tp
#endif
    cincoffset  csp, csp, t3
    csetbounds  csp, csp, t1
    cincoffset  csp, csp, t1
#else
    add     t0, t0, t1
#ifndef SINGLE_CORE
    mul     t1, t1, tp
    add     t0, t0, t1
#endif
    mv      sp, t0
#endif

    LOAD_ADDR  t0, primary_hart_valid
    cspecialr   cs0, ddc
    cfromptr    ct0, cs0, t0
    li  t1, 1
1:
#ifdef __CHERI_PURE_CAPABILITY__
    clr.w  t2, (ct0)
#else
    lr.w  t2, (t0)
#endif
    bnez  t2, skip
#ifdef __CHERI_PURE_CAPABILITY__
    csc.w  t2, t1, (ct0)
#else
    sc.w  t2, t1, (t0)
#endif
    bnez  t2, 1b
    LOAD_ADDR    t0, primary_hart
    cfromptr    ct0, cs0, t0
#ifdef __CHERI_PURE_CAPABILITY__
    csw   a0, 0(ct0)
#else
    sw    a0, 0(t0)
#endif

    /* Clear bss */ 
    LOAD_ADDR t0, __bss_start
    cfromptr  ct0, cs0, t0
    LOAD_ADDR t1, __bss_end
#if __CHERI_PURE_CAPABILITY__
    sub t2, t1, t0
    csetbounds ct0, ct0, t2
#endif
    bgeu t0, t1, 2f
1:
#ifdef __CHERI_PURE_CAPABILITY__
    csw zero, (ct0)
    cincoffset ct0, ct0, 4
#else
    sw zero, (t0)
    addi t0, t0, 4
#endif
    bltu t0, t1, 1b
2:
#if __CHERI__
    #if __CHERI_PURE_CAPABILITY__
    // Initialize and clear the DDC capability
        cspecialr cs0, ddc
        //cmove ct0, cnull
        //cspecialw ddc, ct0
    #else
        cspecialr cs0, ddc
    #endif
    // Initialize the CAP relocs
    cllc cra, cheri_init_caps_reloc
    cmove cs1, ca0
    cmove ca0, cs0
    cspecialr ca1, pcc
    cjalr cra
    cmove ca0, cs1
#endif

.pushsection .data
.align 3
primary_hart_ready: .word 0x0
.popsection

    LOAD_ADDR   t0, primary_hart_ready
    cfromptr    ct0, cs0, t0
    li          t1, 1
#if __CHERI_PURE_CAPABILITY__
    csw         t1, 0(ct0)
#else
    sw          t1, 0(t0)
#endif

skip:

    LOAD_ADDR t0, exception_handler
    #ifdef __CHERI_PURE_CAPABILITY__
        cgetaddr t1, ct0
        and t1, t1, ~STVEC_MODE_MSK
        or t1, t1, STVEC_MODE_DIRECT
        csetaddr ct0, ct0, t1
        cspecialw stcc, ct0
    #else
        and     t0, t0, ~STVEC_MODE_MSK
        or      t0, t0, STVEC_MODE_DIRECT
        csrw    stvec, t0
    #endif

    LOAD_ADDR   t0, primary_hart_ready
1:
    #ifdef __CHERI_PURE_CAPABILITY__
        clw          t1, 0(ct0)
    #else
        lw          t1, 0(t0)
    #endif
    beqz        t1, 1b

    //TODO: other c runtime init (ctors, etc...)
    
    /* Jump to main */
    #ifdef __CHERI_PURE_CAPABILITY__
        cllc        cra, _init
        cjalr       cra
    #else
        call _init
    #endif
    j .
    .size   _start, . - _start

.global _fini
_fini:
#if __CHERI_PURE_CAPABILITY__
    cret
#else
    ret
#endif

.section ".rodata", "a"
    .globl _heap_base_sym
    .type  _heap_base_sym, @object
    .size  _heap_base_sym, 8
_heap_base_sym:
    .dword _heap_base
