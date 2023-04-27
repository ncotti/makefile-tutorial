set architecture arm
target remote localhost:2159
lay regs
b _start
c
