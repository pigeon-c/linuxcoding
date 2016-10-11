#include "apue.h"

#define BUFFSIZE 4096

int main(void)
{
int n;
char buf[BUFFSIZE];

while((n=read(0,buf,BUFFSIZE)) > 0)
	if(write(1,buf,n) !=n)
		printf("write error\n");

if(n<0)
	printf("read error\n");

exit(0);

}
// ./my_copyfile <inputfile >outputfile  
