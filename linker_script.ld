OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

_dst_addr   = 0x70030000;
_stack_addr = 0x70020000;

MEMORY {
    rom     (rx)    :   ORIGIN = 0x70010000, LENGTH = 0x1000
    ram     (wa)    :   ORIGIN = _dst_addr, LENGTH = 0x1000
    stack   (wa)    :   ORIGIN = _stack_addr, LENGTH = 0x1000
}

SECTIONS {    
    .text : {
        *main.o(.text)
        *(.text*)
    } >rom

    .data : { *(.data*) } >rom

    .bss : {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        __bss_end__ = .;
        } >rom
} 