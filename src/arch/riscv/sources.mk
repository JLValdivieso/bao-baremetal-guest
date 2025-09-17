arch_c_srcs:= init.c plic.c sbi.c exceptions.c irq.c timer.c
arch_s_srcs:= start.S

ifeq ($(ARCH_SUB), riscv64xcheri)
arch_c_srcs+=cheri_cap_relocs.c
arch_c_srcs+=cheri_utils.c
endif
