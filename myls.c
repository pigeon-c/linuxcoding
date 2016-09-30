#include "apue.h"

int main(int argc,char* argv[])
{
DIR *dp;
struct dirent *dirp;

if(argc != 2)
{

	printf("Please input the directory's name\n");
	exit(1);
}


if((dp = opendir(argv[1])) == NULL)
{
	printf("can't open %s\n",argv[1]);
	exit(1);

}

while((dirp=readdir(dp)) != NULL)
	printf("%s\n",dirp->d_name);

closedir(dp);

exit(0);
}	
