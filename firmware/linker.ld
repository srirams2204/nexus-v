/* Tell the linker our target architecture and the first instruction to run */
OUTPUT_ARCH( "riscv" )
ENTRY( _start )

/* * 1. THE MEMORY MAP 
 * This must perfectly match your Verilog decoder wires!
 */
MEMORY
{
  /* is_imem_addr = (ALUOut[31:12] == 20'h00000) */
  IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
  
  /* is_dmem_addr = (ALUOut[31:12] == 20'h00001) */
  DMEM (rwx) : ORIGIN = 0x00001000, LENGTH = 4K

  /* is_apb_addr  = (ALUOut[31:16] == 16'h4000) */
  APB  (rw)  : ORIGIN = 0x40000000, LENGTH = 64K
}

/* * 2. THE SECTIONS 
 * Mapping code and variables to the physical memory blocks.
 */
SECTIONS
{
  /* --- INSTRUCTION MEMORY --- */
  .text :
  {
    /* The startup assembly must be at the very beginning of IMEM (0x00000000) */
    KEEP(*(.init))      
    
    /* Align trap handler to 0x100 to match your hardware tests */
    . = 0x100;          
    KEEP(*(.trap))      
    
    /* Place all standard C/Assembly functions after the trap handler */
    *(.text .text.*)    
  } > IMEM

  /* --- DATA MEMORY --- */
  
  /* Read-only data (e.g., const int, string literals like "Hello World") */
  .rodata :
  {
    . = ALIGN(4);
    *(.rodata .rodata.*)
  } > DMEM

  /* Initialized global and static variables */
  .data :
  {
    . = ALIGN(4);
    _sdata = .;        /* Save the start address of .data */
    *(.data .data.*)
    _edata = .;        /* Save the end address of .data */
  } > DMEM

  /* Uninitialized global variables (BSS) */
  .bss :
  {
    . = ALIGN(4);
    _sbss = .;         /* Save the start address of .bss */
    *(.bss .bss.*)
    *(COMMON)
    _ebss = .;         /* Save the end address of .bss */
  } > DMEM

  /* * 3. THE STACK POINTER 
   * The stack grows downwards. We set it to the very top of the DMEM.
   * 0x1000 + 4K (0x1000) = 0x2000
   */
  _sp = ORIGIN(DMEM) + LENGTH(DMEM);
}