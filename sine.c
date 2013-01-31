#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define samples         10000

#define mainsfrequency  50      //Frequency of the mains in Hz
#define samplerate      12800   //Rate that samples are made
#define PI              3.141   //Needs more decimal places

#define step            2*PI*50/12800

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
