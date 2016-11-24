#include <stdio.h>
#include <unistd.h>

int main()
{

char c[1024];

while(fgets(c,1023,stdin) != NULL)
{
	fputs(c,stdout);
}

printf("The program is over\n");


}

