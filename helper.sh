#!/bin/bash
# Run this in your template directory

# Clone repos if not present
[ ! -d "cmsis_device_f4" ] && git clone https://github.com/STMicroelectronics/cmsis_device_f4
[ ! -d "CMSIS_5" ] && git clone https://github.com/ARM-software/CMSIS_5

# Create structure
mkdir -p cmsis/{core,device} startup src

# Copy STM32F4 device files
cp cmsis_device_f4/Include/stm32f4xx.h cmsis/device/
cp cmsis_device_f4/Include/stm32f411xe.h cmsis/device/
cp cmsis_device_f4/Include/system_stm32f4xx.h cmsis/device/
cp cmsis_device_f4/Source/Templates/system_stm32f4xx.c cmsis/device/

# Copy startup
cp cmsis_device_f4/Source/Templates/gcc/startup_stm32f411xe.s startup/

# Copy ALL necessary CMSIS core files
cp CMSIS_5/CMSIS/Core/Include/core_cm4.h cmsis/core/
cp CMSIS_5/CMSIS/Core/Include/cmsis_version.h cmsis/core/
cp CMSIS_5/CMSIS/Core/Include/cmsis_compiler.h cmsis/core/
cp CMSIS_5/CMSIS/Core/Include/cmsis_gcc.h cmsis/core/
cp CMSIS_5/CMSIS/Core/Include/mpu_armv7.h cmsis/core/

# Create linker script
cat > startup/STM32F411RETx_FLASH.ld << 'EOF'
/* Entry Point */
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = ORIGIN(RAM) + LENGTH(RAM);

/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 0x200;
_Min_Stack_Size = 0x400;

/* Specify the memory areas */
MEMORY
{
  FLASH (rx)      : ORIGIN = 0x08000000, LENGTH = 512K
  RAM (xrw)       : ORIGIN = 0x20000000, LENGTH = 128K
}

/* Define output sections */
SECTIONS
{
  .isr_vector :
  {
    . = ALIGN(4);
    KEEP(*(.isr_vector))
    . = ALIGN(4);
  } >FLASH

  .text :
  {
    . = ALIGN(4);
    *(.text)
    *(.text*)
    *(.glue_7)
    *(.glue_7t)
    *(.eh_frame)
    KEEP (*(.init))
    KEEP (*(.fini))
    . = ALIGN(4);
    _etext = .;
  } >FLASH

  .rodata :
  {
    . = ALIGN(4);
    *(.rodata)
    *(.rodata*)
    . = ALIGN(4);
  } >FLASH

  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } >FLASH
  .ARM : {
    __exidx_start = .;
    *(.ARM.exidx*)
    __exidx_end = .;
  } >FLASH

  .preinit_array :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } >FLASH

  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } >FLASH

  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } >FLASH

  _sidata = LOADADDR(.data);

  .data :
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.data*)
    . = ALIGN(4);
    _edata = .;
  } >RAM AT> FLASH

  . = ALIGN(4);
  .bss :
  {
    _sbss = .;
    __bss_start__ = _sbss;
    *(.bss)
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
    __bss_end__ = _ebss;
  } >RAM

  ._user_heap_stack :
  {
    . = ALIGN(8);
    PROVIDE ( end = . );
    PROVIDE ( _end = . );
    . = . + _Min_Heap_Size;
    . = . + _Min_Stack_Size;
    . = ALIGN(8);
  } >RAM

  /DISCARD/ :
  {
    libc.a ( * )
    libm.a ( * )
    libgcc.a ( * )
  }

  .ARM.attributes 0 : { *(.ARM.attributes) }
}
EOF

# Cleanup
rm -rf cmsis_device_f4 CMSIS_5

echo "Template ready!"
