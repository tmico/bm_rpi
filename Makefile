<<<<<<< HEAD
###############################################################################
#
#	A makefile script for generation of raspberry pi kernel images.
#
###############################################################################

# ===========================================================
# The compiler to use and flags 
# ===========================================================
ARMGNU ?= arm-none-eabi

# ASFLAGS for debugging
ASFLAGS = -g


# ===========================================================
# The directories for source and compiled object files.
# ===========================================================
BUILD = build/

BUILD_GDB = build_gdb/

SOURCE = source/


# ===========================================================
# The name of the output files to generate.
# ===========================================================
KERNEL = kimage

KERNELGZ = kimage.gz

UIMAGE = uimage

ZIMAGE = zimage

LIST = kernel.list

MAP = kernel.map

GDBELF = kgdb.elf

LINKER = kernel.ld


# ===========================================================
# Rules to make object files deduced from source files and
# build kernel 
# ===========================================================
OBJECTS := $(patsubst $(SOURCE)%.s,$(BUILD)%.o,$(wildcard $(SOURCE)*.s))

# Rule to make everything.
all: $(KERNEL) $(LIST) $(UIMAGE) $(ZIMAGE)

rebuild: clean all

$(LIST): $(BUILD)kimage.elf
	$(ARMGNU)-objdump -D $(BUILD)kimage.elf > $(LIST)

$(KERNEL): $(BUILD)kimage.elf
	$(ARMGNU)-objcopy --strip-debug $(BUILD)kimage.elf -O binary $(KERNEL)

$(BUILD)kimage.elf: $(OBJECTS)
	$(ARMGNU)-ld --no-undefined $(OBJECTS) -Map $(MAP) -o $(BUILD)kimage.elf -T $(LINKER)

$(BUILD)%.o: $(SOURCE)%.s $(BUILD)
	$(ARMGNU)-as $(ASFLAGS) -I $(SOURCE) $< -o $@


# ===========================================================
# Rule to make gzip'ed and u-boot bootable image files
# ===========================================================
$(KERNELGZ): $(KERNEL)
	gzip -k -f $(KERNEL)

$(UIMAGE): $(KERNEL)
	@ echo "Invoking mkimage to make an uncompressed image"
	mkimage -A arm -T kernel -C none -a 0x8000 -e 0x8000 -n "virus-0.0" -d $(KERNEL)  $(UIMAGE)

$(ZIMAGE): $(KERNELGZ)
	@ echo "Invoking mkimage to make an compressed image"
	mkimage -A arm -T kernel -C gzip -a 0x8000 -e 0x8000 -n "virus-0.0" -d $(KERNELGZ) $(ZIMAGE)


# ============================================================
# Rules to create kgdb.elf
# ============================================================
OBJ := $(patsubst $(SOURCE)%.s,$(BUILD_GDB)%.o,$(wildcard $(SOURCE)*.s))

debug: $(GDBELF)

$(BUILD_GDB)%.o: $(SOURCE)%.s $(BUILD_GDB)
	as $(ASFLAGS) -I $(SOURCE) $< -o $@

$(GDBELF): $(OBJ)
	ld --no-undefined $(OBJ) -o $(GDBELF) 
	objdump -D $(GDBELF) > $(GDBELF).list


#============================================================
# Rules to make directories and what to delete when cleaning
# ===========================================================
$(BUILD):
	mkdir $@

$(BUILD_GDB):
	mkdir $@

# Rule to clean files.
clean:
	-rm -rf $(BUILD)
	-rm -rf $(BUILD_GDB)
	-rm -f $(KERNEL)
	-rm -f $(LIST)
	-rm -f $(MAP)
	-rm -f $(KERNELGZ)
	-rm -f $(UIMAGE)
	-rm -f $(ZIMAGE)
	-rm -f $(GDBELF)
	-rm -f $(GDBELF).list
=======
###############################################################################
#
#	A makefile script for generation of raspberry pi kernel images.
#
###############################################################################
DEBUG =

# ===========================================================
# The compiler and flags to use set depending on debug option
# ===========================================================
CROSS_TOOLS ?= arm-none-eabi-
HOST_TOOLS =

ifeq ($(DEBUG),yes)
	ARMGNU = $(HOST_TOOLS)
	ASFLAGS = -g --defsym DEBUG=1
else
	ARMGNU = $(CROSS_TOOLS)
	ASFLAGS = -g
endif

# ===========================================================
# The directories for source and compiled object files.
# ===========================================================
BUILD = build/

BUILD_GDB = build_gdb/

SOURCE = source/


# ===========================================================
# The name of the output files to generate.
# ===========================================================
KERNELDBG = kernelgdb.elf
KERNEL = kimage.elf

ifeq ($(DEBUG),yes)
	IMAGE_ELF = $(KERNELDBG)
else
	IMAGE_ELF = $(KERNEL)
endif

IMAGE = kimage

KERNELGZ = kimage.gz

UIMAGE = uimage

ZIMAGE = zimage

LIST = kernel.list

MAP = kernel.map

GDBMAP = kernelgdb.map

LINKER = kernel.ld


# ===========================================================
# Rules to make object files deduced from source files and
# build kernel 
# If DEBUG=yes is passed to make, a gdb usable (but not 
#  perfect) kernelgdb.elf image is built
# ===========================================================
OBJECTS := $(patsubst $(SOURCE)%.s,$(BUILD)%.o,$(wildcard $(SOURCE)*.s))

all: $(IMAGE) $(LIST) $(UIMAGE) $(ZIMAGE) 

rebuild: clean all

$(LIST): $(BUILD)$(IMAGE_ELF)
	$(ARMGNU)objdump -D $(BUILD)$(IMAGE_ELF) > $(LIST)


$(IMAGE): $(BUILD)$(IMAGE_ELF)
	$(ARMGNU)objcopy --strip-debug $(BUILD)$(IMAGE_ELF) -O binary $(IMAGE)


$(BUILD)$(IMAGE_ELF): $(OBJECTS)
	$(ARMGNU)ld --no-undefined $(OBJECTS) -Map $(MAP) -T $(LINKER) -o $(BUILD)$(IMAGE_ELF) 


$(BUILD)%.o: $(SOURCE)%.s $(BUILD)
	$(ARMGNU)as $(ASFLAGS) -I $(SOURCE) $< -o $@


# ===========================================================
# Rule to make gzip'ed and u-boot bootable image files
# ===========================================================
$(KERNELGZ): $(IMAGE)
ifneq ($(DEBUG),yes)
	@#gzip -k -f $(IMAGE)
	gzip -f -c $(IMAGE) > $(KERNELGZ) 
endif

$(UIMAGE): $(IMAGE)
ifneq ($(DEBUG),yes)
	@ echo "Invoking mkimage to make an uncompressed image"
	mkimage -A arm -T kernel -C none -a 0x8000 -e 0x8000 -n "virus-0.0" -d $(IMAGE)  $(UIMAGE)
endif

$(ZIMAGE): $(KERNELGZ)
ifneq ($(DEBUG),yes)
	@ echo "Invoking mkimage to make an compressed image"
	mkimage -A arm -T kernel -C gzip -a 0x8000 -e 0x8000 -n "virus-0.0" -d $(KERNELGZ) $(ZIMAGE)
endif

#============================================================
# Rules to make directories and what to delete when cleaning
# ===========================================================
$(BUILD):
	mkdir $@

$(BUILD_GDB):
	mkdir $@

# Rule to clean files.
clean:
	-rm -rf $(BUILD)
	-rm -rf $(BUILD_GDB)
	-rm -f $(KERNEL)
	-rm -f $(LIST)
	-rm -f $(MAP)
	-rm -f $(KERNELGZ)
	-rm -f $(UIMAGE)
	-rm -f $(ZIMAGE)
	-rm -f $(GDBELF)
	-rm -f $(GDBELF).list

#	@ echo "**********************************************************"
#	@ echo "* The DEBUG=yes can only work if compiling on an arm host"
#	@ echo "**********************************************************"
>>>>>>> cb0575113d39aea57cc66b3926bfad37f7ae8123
