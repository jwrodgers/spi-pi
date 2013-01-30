// Run this on the PI.
// Needs wiringPI installed to work correctly
// Outputs the data received as values from the A/D, Filters 7E padding/escapes inserted at PIC side


#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <wiringPi.h>
#include <time.h>
#include <sys/timeb.h>

//Strips out 0x7E symbols from data stream


void main(void){

    struct tm *tm_ptr;
    time_t the_time;

    (void) time(&the_time);
    tm_ptr = gmtime(&the_time);


/* fast timeb function for milliseconds */
 
    struct timeb tmb;
    struct timeb starttime;
    struct timeb stoptime;



unsigned char buffer[4096];
unsigned char data[4096];
int i;
for(i=0;i<4096;i++){
  buffer[i]=0xAA;
	data[i]=0x55;
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



ftime(&starttime);
int j=0;
for(j=0; j<1; j++){

       wiringPiSPIDataRW ( channel, &buffer, 4096) ;

}
        ftime(&stoptime);

//copy buffer to data removing 0x7E symbols
int k=0;
for(j=0; j<4096; j++)
{
	if(buffer[j]==0x7E)continue;

	if(buffer[j]==0x7D){
		if(buffer[j+1]==0x5E){
			data[k]=0x7E;
			j++;
			k++;
			continue;
		}
		if(buffer[j+1]==0x5D){
			data[k]=0x7D;
                        j++;
                        k++;
                        continue;
		}
	}
	data[k]=buffer[j];
	k++;
}





for(i=0;i<k;i+=2){
	
	//Uncomment for DEBUG:
//	printf("%d, 0x%X\n", i, data[i]);
//	printf("%d, 0x%X     ", i+1, data[i+1]);	


	printf("%d,%d\n", i, data[i]*256+data[i+1]);
}



}
