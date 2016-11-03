#include "../apue.h"


int main(int argc,char** argv)
{
	int sockfd,n;
	char recvline[1024];
	struct sockaddr_in servaddr;

	if(argc != 2)
		perror("usage:a.out <IPaddress>");

	if( (sockfd = socket(AF_INET,SOCK_STREAM,0)) < 0)
		perror("socket error");

	bzero(&servaddr,sizeof(servaddr));

	servaddr.sin_family = AF_INET;
	servaddr.sin_port = htons(13);/*daytime server*/
	if(inet_pton(AF_INET,argv[1],&servaddr.sin_addr) <= 0)
		perror("inet_pton error");

	if(connect(sockfd,(struct sockaddr*)&servaddr,sizeof(servaddr)) <0)
		perror("connect error");

	while( (n = read(sockfd,recvline,1023)) >0 )
	{
		recvline[n] = 0;
		if(fputs(recvline,stdout) == EOF)
			perror("fputs error");
	}
	
	if(n < 0)
		perror("read error");

	exit(0);
}


