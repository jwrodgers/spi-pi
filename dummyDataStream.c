// testwiringPI file

int wiringPiSPIDataRW ( int channel, unsigned char *buffer, int length )
{
  int i;
  
  for(i=0; i<length; i++){
    *buffer = (char)i;
    buffer++;
  }
  
  return 0;
}
