#include <stdio.h>
#include <stdlib.h>

#define RST_ACTIVE_LOW 0x80000000

int main() {

    volatile int err = 0;
    volatile int value = 0;

    printf("Read reset value of the PL\r\n");
    system("devmem 0xFF0A0054 w");

    printf("Assert reset for the PL\r\n");
    system("devmem 0xFF0A0054 32 0x00000000");

    printf("Release reset for the PL\r\n");
    system("devmem 0xFF0A0054 32 0x80000000");

    printf("Read reset value of the PL\r\n");
    FILE *output = popen("devmem 0xFF0A0054 w", "r");
    fscanf(output, "0x%08x", &value);
    pclose(output);

    if (value != RST_ACTIVE_LOW) {
        err++;
    }

    return err;
}
