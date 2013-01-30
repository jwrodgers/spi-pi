// Run on Raspberry PI
// Requires wiringPI
// Writes out recieved data in Hex
// Lots of bugs still exist and code is very smelly!

#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <wiringPi.h>
#include <time.h>
#include <sys/timeb.h>


void main(void){

    struct tm *tm_ptr;
    time_t the_time;

    (void) time(&the_time);
    tm_ptr = gmtime(&the_time);

    printf("The Raw time is %ld\n", the_time);

/* fast timeb function for milliseconds */
 
    struct timeb tmb;
    struct timeb starttime;
    struct timeb stoptime;



unsigned char buffer[4096];
int i;
for(i=0;i<4096;i++){
  buffer[i]=0xAA;
}

/*
buffer[0]=0;
buffer[1]=1;
buffer[2]=2;
buffer[3]=3;
buffer[4]=4;
buffer[5]=0xAA;
buffer[6]=0x55;

*/
int channel=0;


if (wiringPiSPISetup (channel, 500000) < 0)
  fprintf (stderr, "SPI Setup failed!\n");

    printf("\n\nEntering SPI Comms:\n");


ftime(&starttime);
int j=0;
for(j=0; j<1; j++){

       wiringPiSPIDataRW ( channel, &buffer, 4096) ;

}
        ftime(&stoptime);
        printf("seconds difference: %ld.%ld\n", stoptime.time-starttime.time);
        printf("millis difference: %ld\n" , stoptime.millitm-starttime.millitm);
// Show each character as recieved
for(i=0;i<4096;i++){
	printf("%d,0x%X\n", i, buffer[i]);
}



}
