OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{ 
  /* Depth 1024 words * 4 bytes = 4096 bytes = 0x1000 */
  MEM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x1000 
}

SECTIONS
{
  .text : {
    *(.text)
  } > MEM

  .data : {
    *(.data)
  } > MEM

  .bss : {
    *(.bss)
  } > MEM
}