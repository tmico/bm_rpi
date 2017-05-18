###############################################################################
#
#	A makefile script for generation of raspberry pi kernel images.
#
#
###############################################################################

# The compiler to use
ARMGNU ?= arm-none-eabi

# ASFLAGS for debugging
ASFLAGS = -g

# The intermediate directory for compiled object files.
BUILD = build/

# The intermediate directory for compiled object files with debug enabled
BUILD_GDB = build_dbg/

# The directory in which source files are stored.
SOURCE = source/

# The name of the output files to generate.
TARGET = kernel.img

TARGETGZ = kernel.img.gz

UIMAGE = uimage

ZIMAGE = zimage

# The name of the assembler listing file to generate.
LIST = kernel.list

# The name of the map file to generate.
MAP = kernel.map

# The name of gdb friendly output file
GDBELF = gdb.elf

# The name of the linker script to use.
LINKER = kernel.ld

# The names of all object files that must be generated. Deduced from the
# assembly code files in source.
OBJECTS := $(patsubst $(SOURCE)%.s,$(BUILD)%.o,$(wildcard $(SOURCE)*.s))
# OBJECTS_GDB := $(patsubst $(SOURCE)%.s,$(BUILD_GDB)%.o,$(wildcard $(SOURCE)*.s))

# Rule to make everything.
all: $(TARGET) $(LIST)#$(GDBELF)

# Rule to remake everything. Does not include clean.
rebuild: all

# Rule to make the listing file.
$(LIST) : $(BUILD)output.elf
	$(ARMGNU)-objdump -D $(BUILD)output.elf > $(LIST)

# Rule to make the image file.
$(TARGET) : $(BUILD)output.elf
	$(ARMGNU)-objcopy $(BUILD)output.elf -O binary $(TARGET)

# Rule to make gzip'ed image
$(TARGETGZ) : $(TARGET)
	gzip -k -f $(TARGET)

# Rule to make uncompressed uimage
uimage :  $(UIMAGE)

# Rule to make compressed zimage
zimage :  $(ZIMAGE)

$(UIMAGE) : $(TARGET)
	@ echo "Invoking mkimage to make an uncompressed image"
	mkimage -A arm -T kernel -C none -a 0x8000 -e 0x8000 -n "virus-0.0" -d kernel.img  $(UIMAGE)

$(ZIMAGE) : $(TARGETGZ)
	@ echo "Invoking mkimage to make an compressed image"
	mkimage -A arm -T kernel -C gzip -a 0x8000 -e 0x8000 -n "virus-0.0" -d kernel.img.gz $(ZIMAGE)

# Rule to make the elf file.
$(BUILD)output.elf : $(OBJECTS) $(LINKER)
	$(ARMGNU)-ld --no-undefined $(OBJECTS) -Map $(MAP) -o $(BUILD)output.elf -T $(LINKER)

# Rule to make gdb friendly file.
$(GDBELF) : $(OBJECTS_GDB) $(LINKER)
	$(ARMGNU)-ld $(OBJECTS_GDB) -o $(BUILD_GDB)$(GDBELF) -T $(LINKER)
#
# Rule to make the object files.
$(BUILD)%.o: $(SOURCE)%.s $(BUILD)
	$(ARMGNU)-as -I $(SOURCE) $< -o $@

# Rule to make debug object files
$(BUILD_GDB)%.o: $(SOURCE)%.s $(BUILD_GDB)
	$(ARMGNU)-as $(ASFLAGS) -I $(SOURCE) $< -o $@

$(BUILD):
	mkdir $@

$(BUILD_GDB):
	mkdir $@

# Rule to clean files.
clean :
	-rm -rf $(BUILD)
	-rm -f $(TARGET)
	-rm -f $(LIST)
	-rm -f $(MAP)
	-rm -f $(TARGETGZ)
	-rm -f $(UIMAGE)
	-rm -f $(ZIMAGE)
