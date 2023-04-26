#include "add1.h"
#include "add2.h"

int __attribute__((section(".text")))add9(int a, short b, char c,
    int d, int e, int f, unsigned int g, unsigned char h, int i) {
    return a + TWO*b + THREE*c + FOUR*d + 5*e + 6*f + 7*g + 8*h + 9*i;
}