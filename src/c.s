.text
.global asm_c, _start
_start:
asm_c:
    ldr r0, =0x55
    add r0, r0, r0, lsl #2
