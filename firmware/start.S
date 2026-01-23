.section .text
.global _start

_start:
    la sp, 0x00002000  /* Set Stack Pointer to top of Data Mem (adjust size as needed) */
    call main          /* Jump to C code */
    
loop:
    j loop             /* Infinite loop if main returns */