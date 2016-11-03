#include "apue.h"
//gcc program.c -lpthread
//one thread input,another thread output

char slt;
int flag = 0;
char str[1024];


void* input_thread(void*e)
{

	while((slt = getchar()) != 'q')
	{       flag = 1;
		getchar();

	}

	pthread_exit(NULL);
}




void* input_thread_1(void*e)
{

	while(1)
	{	
		if(flag == 1)
		{
			flag = 0;
			putchar(slt);
		}
	}	

	return 0;
}




void main()
{

	pthread_t pid1,pid2;

	pthread_create(&pid1,NULL,input_thread,NULL);
	pthread_create(&pid2,NULL,input_thread_1,NULL);

	printf("This is the main thread\n");


	pthread_join(pid1,NULL);
	pthread_join(pid2,NULL);

}

