#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define samples 100
#define step    0.001



int main(void){
    int i;
    for(i=0; i<samples; i++){
        printf("%d", i);
    }
    return(EXIT_SUCCESS);
}
