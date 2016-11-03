#include "apue.h"
//gcc program.c -lpthread
//one thread input and output a character,another thread output something per 5s

void* input_thread(void*e)
{
	char c;

	while((c = getchar()) != 'q')
	{
		getchar();
		printf("The character is <%c>\n",c);

	}

	return 0;

}




void* input_thread_1(void*e)
{

	while(1)
	{	
		sleep(5);
		printf("hello pigeon\n");

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

