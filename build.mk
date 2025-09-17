
gen_ld_file:=$(BUILD_DIR)/linker.ld

objs:=$(C_SRC:$(ROOT_DIR)/%.c=$(BUILD_DIR)/%.o) \
	$(ASM_SRC:$(ROOT_DIR)/%.S=$(BUILD_DIR)/%.o)
deps:=$(objs:%=%.d) $(gen_ld_file).d
dirs:=$(sort $(dir $(objs) $(deps)))

SYSROOT:=/media/ninolomata/Nino1/CHERI/cheri_install/output/sdk/baremetal

# Check cross compiler
ifneq ($(findstring clang,$(CROSS_COMPILE)),)
CC_IS_CLANG =	y
else
CC_IS_GCC =	y
endif

ifdef CC_IS_CLANG
clang_version:=$(strip $(patsubst clang%, %, $(notdir $(CROSS_COMPILE))))
clang_path:=$(dir $(wildcard $(abspath $(CROSS_COMPILE))))
cpp=		$(clang_path)clang-cpp$(clang_version)
sstrip= 	$(clang_path)llvm-strip$(clang_version)
cc=			$(clang_path)clang$(clang_version)
ld = 		$(clang_path)ld.lld$(clang_version)
as=			$(clang_path)llvm-as$(clang_version)
objcopy=	$(clang_path)llvm-objcopy$(clang_version)
objdump=	$(clang_path)llvm-objdump$(clang_version)
readelf=	$(clang_path)llvm-readelf$(clang_version)
size=		$(clang_path)llvm-size$(clang_version)
else
cpp=		$(CROSS_COMPILE)cpp
sstrip= 	$(CROSS_COMPILE)strip
cc=			$(CROSS_COMPILE)gcc
ld = 		$(CROSS_COMPILE)ld
as=			$(CROSS_COMPILE)as
objcopy=	$(CROSS_COMPILE)objcopy
objdump=	$(CROSS_COMPILE)objdump
readelf=	$(CROSS_COMPILE)readelf
size=		$(CROSS_COMPILE)size
endif

OPT_LEVEL = 2
DEBUG_LEVEL = 3

debug_flags:= -g$(DEBUG_LEVEL) $(arch_debug_flags) $(platform_debug_flags)
GENERIC_FLAGS = $(ARCH_GENERIC_FLAGS) -O$(OPT_LEVEL) $(debug_flags) -static
CPPFLAGS += $(ARCH_CPPFLAGS) $(addprefix -I, $(INC_DIRS)) -MD -MF $@.d
ifneq ($(STD_ADDR_SPACE),)
CPPFLAGS+=-DSTD_ADDR_SPACE
endif
ifneq ($(MPU),)
CPPFLAGS+=-DMPU
endif
ifneq ($(MEM_BASE),)
CPPFLAGS+=-DMEM_BASE=$(MEM_BASE)
endif
ifneq ($(MEM_SIZE),)
CPPFLAGS+=-DMEM_SIZE=$(MEM_SIZE)
endif
ifneq ($(SINGLE_CORE),)
CPPFLAGS+=-DSINGLE_CORE=y
endif
ifneq ($(NO_FIRMWARE),)
CPPFLAGS+=-DNO_FIRMWARE=y
endif
ifeq ($(CC_IS_GCC),y)
	CPPFLAGS+=-DCC_IS_GCC
else ifeq ($(CC_IS_CLANG),y)
	CPPFLAGS+=-DCC_IS_CLANG
endif
ASFLAGS += $(GENERIC_FLAGS) $(CPPFLAGS) $(ARCH_ASFLAGS) 
CFLAGS += $(GENERIC_FLAGS) $(CPPFLAGS) $(ARCH_CFLAGS) 
LDFLAGS += $(GENERIC_FLAGS) $(ARCH_LDFLAGS) -nostartfiles

target:=$(BUILD_DIR)/$(NAME)
all: $(target).bin

ifneq ($(MAKECMDGOALS), clean)
-include $(deps)
endif

$(target).bin: $(target).elf
	$(objcopy) -O binary $< $@

$(target).elf: $(objs) $(gen_ld_file)
	$(cc) $(LDFLAGS) -T$(gen_ld_file) $(objs) -o $@
	$(objdump) -S $@ > $(target).asm
	$(objdump) -x -d --wide $@ > $(target).lst

$(BUILD_DIR):
	mkdir -p $@

$(objs): | $(BUILD_DIR)

$(BUILD_DIR)/%.o: $(ROOT_DIR)/%.c
	@echo $@
	$(cc) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(ROOT_DIR)/%.S
	@echo $@
	@$(cc) $(ASFLAGS) -c $< -o $@

$(gen_ld_file): $(LD_FILE)
	@$(cc) $(CPPFLAGS) -E -x assembler-with-cpp $< | grep "^[^#;]" > $@

.SECONDEXPANSION:

$(objs) $(deps): | $$(@D)/

$(dirs):
	mkdir -p $@

clean:
	@rm -rf $(BUILD_DIR)

.PHONY: all clean
