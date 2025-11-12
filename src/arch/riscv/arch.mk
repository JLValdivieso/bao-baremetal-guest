CROSS_COMPILE ?= riscv64-unknown-elf-
ARCH_SUB ?= riscv64xcheri
ifeq ($(ARCH_SUB), riscv64xcheri)
ARCH_GENERIC_FLAGS = -mcmodel=medany -march=rv64imafdxcheri -mabi=l64pc128 --target=riscv64 --sysroot=$(SYSROOT)/baremetal-newlib-riscv64-purecap/riscv64-unknown-elf
ARCH_ASFLAGS = --sysroot=$(SYSROOT)/baremetal-newlib-riscv64-purecap/riscv64-unknown-elf
ARCH_LDFLAGS = --target=riscv64 --sysroot=$(SYSROOT)/baremetal-newlib-riscv64-purecap/riscv64-unknown-elf -lclang_rt.builtins-riscv64 -L$(SYSROOT)/baremetal-riscv64-purecap/lib
else
ARCH_GENERIC_FLAGS = -mcmodel=medany -march=rv64imac -mabi=lp64
ARCH_ASFLAGS = 
ARCH_LDFLAGS = --specs=nano.specs
endif
ARCH_CFLAGS = 
ARCH_CPPFLAGS =	
