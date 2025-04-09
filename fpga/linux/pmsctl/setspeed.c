#include <stdio.h>
#include <stdlib.h>

#define MAX_LEN 10

int main(int argc, char *argv[]) {
    FILE *fp;
    fp = fopen("/sys/devices/system/cpu/cpu0/cpufreq/scaling_setspeed", "w");
    if(fp == NULL){
        printf("error opening file");
        return 0;
    }
    fprintf(fp, "%s", argv[1]);
    return 1;
}
