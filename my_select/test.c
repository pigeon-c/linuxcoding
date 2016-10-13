#include "apue.h"


int kbhit(void)
{
	struct timeval tv = {0};
	fd_set read_fd;
	int ret = 0;

	FD_ZERO(&read_fd);
	FD_SET(0,&read_fd);

	if((ret = select(1,&read_fd,NULL,NULL,&tv)) == -1)
	{
		printf("this is wrong\n");
       		return 0;
	
	}	


	if(FD_ISSET(0,&read_fd))
	{
        	return 1;
	}

	return 0;
}



int main()
{


	while(!kbhit());

	printf("Someone pressed the key,and the test is over\n");

	return 0;
}

