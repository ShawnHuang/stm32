#
# all: libraries.cpp main.cpp
#        $@ = all, $< = libraries.cpp, $^ = libraries.cpp main.cpp
#

# DECLARATIONS

# Directory where QEMU_STM32 ARM executable is located - used for running
# program in emulator.
QEMU_ARM_DIR ?= ./qemu_stm32/arm-softmmu/

# OpenOCD interface file used for programming/debugging the micronctroller
OPENOCD_INTERFACE ?= openocd/interface/olimex-arm-usb-tiny-h.cfg

# Declare command line tools - assume these are in the path
CC	  = arm-none-eabi-gcc
LD	  = arm-none-eabi-ld
AS	  = arm-none-eabi-as
CP	  = arm-none-eabi-objcopy
OD	  = arm-none-eabi-objdump

# Declare command line flags
CORE_CFLAGS = -I./ -I$(CORE_SRC) -I$(DEVICE_SRC) -I$(STD_PERIPH)/inc -I./common -fno-common -O0 -g -mcpu=cortex-m3 -mthumb 
CFLAGS  = $(CORE_CFLAGS) -c 
CFLAGS_LINK = -Wl,-T./main.ld -nostartfiles $(CORE_CFLAGS)
ASFLAGS = -mcpu=cortex-m3 -mthumb -g
LDFLAGS = -T./main.ld -nostartfiles
CPFLAGS = -Obinary
ODFLAGS	= -S

# Declare library source paths
SRC = $(realpath .)
CORE_SRC = $(SRC)/libraries/CMSIS/CM3/CoreSupport
DEVICE_SRC = $(SRC)/libraries/CMSIS/CM3/DeviceSupport/ST/STM32F10x
STD_PERIPH = $(SRC)/libraries/STM32F10x_StdPeriph_Driver
STD_PERIPH_SRC = $(STD_PERIPH)/src

# List common and system library source files
# (i.e. for accessing STM32/Cortex M3 hardware) 
COMMON_FILES = $(CORE_SRC)/core_cm3.c
COMMON_FILES += $(DEVICE_SRC)/system_stm32f10x.c
COMMON_FILES += $(DEVICE_SRC)/startup/gcc_ride7/startup_stm32f10x_md.s
COMMON_FILES += ./common/stm32_p103.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_rcc.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_gpio.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_usart.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_exti.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_adc.c
COMMON_FILES += $(STD_PERIPH_SRC)/stm32f10x_tim.c
COMMON_FILES += $(STD_PERIPH_SRC)/misc.c

# List FreeRTOS resources
FREE_RTOS_SRC = $(SRC)/libraries/FreeRTOS
FREE_RTOS_SRC_FILES = $(FREE_RTOS_SRC)/croutine.c $(FREE_RTOS_SRC)/list.c $(FREE_RTOS_SRC)/queue.c $(FREE_RTOS_SRC)/tasks.c $(FREE_RTOS_SRC)/croutine.c $(FREE_RTOS_SRC)/portable/GCC/ARM_CM3/port.c
FREE_RTOS_INC = $(FREE_RTOS_SRC)/include/
FREE_RTOS_PORT_INC = $(FREE_RTOS_SRC)/portable/GCC/ARM_CM3/

# Declare target names for each demo
TARGET = project

# Generic targets
.PHONY: clean $(TARGET) PROG openocd_dbg

all: $(TARGET)

print-%  : ; @echo $* = $($*)

clean:
	find . -type f -name "*.o" -exec rm {} \;
	find . -type f -name "*.elf" -exec rm {} \;
	find . -type f -name "*.bin" -exec rm {} \;
	find . -type f -name "*.list" -exec rm {} \; 

# Compile targets (builds all output files)
$(TARGET) : ./main.elf ./main.bin ./main.list

# Targets to program a microntroller using OpenOCD
PROG : $(TARGET)
	-killall -q openocd
	openocd -f $(OPENOCD_INTERFACE) -f openocd/openocd_stm32_p103.cfg -c "program_flash ./main.bin"

# Target to launch OpenOCD - by default, OpenOCD creates a GDB server at port 3333.
DBG:
	-killall -q openocd
	openocd -f $(OPENOCD_INTERFACE) -f openocd/openocd_stm32_p103.cfg -c "init_stm32"
	
# QEMU run targets
QEMURUN : $(TARGET) 
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -kernel ./main.bin

QEMURUN_PTY : $(TARGET)
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -kernel ./main.bin -serial pty
	
QEMURUN_TEL : $(TARGET)
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -kernel ./main.bin -serial tcp::7777,server

# QEMU debug targets
QEMUDBG : $(TARGET)
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -gdb tcp::3333 -S -kernel ./main.bin

QEMUDBG_PTY : $(TARGET)
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -gdb tcp::3333 -S -kernel ./main.bin -serial pty
	
QEMUDBG_TEL : $(TARGET)
	-killall -q qemu-system-arm
	$(QEMU_ARM_DIR)qemu-system-arm -M stm32-p103 -gdb tcp::3333 -S -kernel ./main.bin -serial tcp::7777,server
	
# Note: Use this command to run QEMU in low-level debug mode:
#    qemu-system-arm -cpu cortex-m3 -M stm32-p103 -nographic -singlestep -kernel main.bin -d in_asm,out_asm,exec,cpu,int,op,op_opt

# Compile targets to build individual files
main.list : main.elf
	$(OD) $(ODFLAGS) $< > $@

main.bin : main.elf
	$(CP) $(CPFLAGS) $< $@

main.elf: main.c
main.elf: $(COMMON_FILES)
	$(CC) $(CFLAGS_LINK) -I./ -o $@ $^
