.global _start
.extern _stack_addr
.extern add9

.text
_start:
    ldr sp, =_stack_addr
    mov r0, #1
    mov r1, #2
    mov r2, #3
    mov r3, #4
    mov r4, #5
    mov r5, #6
    mov r6, #7
    mov r7, #8
    mov r8, #9
    push {r4-r8}
    bl add9     // r0 = 1 + 2*2 + 3*3 + 4*4 + 5*5 + 6*6 + 7*7 + 8*8 + 9*9 = 285
    add sp, sp, #20 // Clear stack 4*5 = 20
