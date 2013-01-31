#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define samples 10000
#define step    0.001



int main(void){
    int i;
    float x,y;
    
    for(i=0; i<samples; i++){
        y=sin(x);
        x=x+step;
        printf("%d,%f\n", i, y);
    }
    return(EXIT_SUCCESS);
}
