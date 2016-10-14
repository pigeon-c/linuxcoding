#include <linux/input.h>
#include <math.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>



int ParseCommandLine(int argc, char * argv[])
{
    int result = 0;
    // Walk all command line arguments.
    if(argc > 1)
    {
        if (argv[1][0] >= '0' && argv[1][0] <= '9')
        {
            result = atoi(&argv[1][0]);
        }
        else
        {
            result = 0;
        }
    }
    else
    {
        result = 0;
    }

    return result;
}



void simulate_key(int fd, int code , int value)
{
  struct input_event event;

  
  //模拟按键按下
  event.type = EV_KEY;      //键盘事件类型
  event.code = code;        //按键键值
  event.value = 1 ;         //1代表按下
  
  
  gettimeofday(&event.time, 0);
  
 
  if(write(fd,&event, sizeof(event))<0)
  {
		printf("simulate key error");
  }
  
  
  //按键同步
  event.type = EV_SYN;
  event.code = SYN_REPORT;
  event.value = 0 ;
  if(write(fd,&event, sizeof(event))<0)
  {
    printf("simulate key error");
  }
  
  
  //按键松开
  event.type = EV_KEY;
  event.code = code;
  event.value = 0 ;
  gettimeofday(&event.time, 0);
  
  if(write(fd,&event, sizeof(event))<0)
  {
    printf("simulate key error");
  }
  
  
  event.type = EV_SYN;
  event.code = SYN_REPORT;
  event.value = 0 ;
  if(write(fd,&event, sizeof(event))<0)
  {
    printf("simulate key error");
  }
  
  
  
}
    
	

	
int main(int argc, char** argv)
{
  int keycode = KEY_ENTER;
  int fd;
  
  fd = open("/dev/input/event2", O_RDWR);
  if(fd <=0)
  {
    printf("error open keyboard \n");
    return -1 ;
  }
  
  

  keycode = ParseCommandLine(argc, argv);
  if(keycode<=0) return 0;
	
	
  simulate_key(fd,keycode,1);

  

//while(1)
//{

  //simulate_key(fd,32,1);
//	sleep(10); 
  
//}  
  
//  sleep(2);
//  simulate_key(fd, keycode,0);



  close(fd);
  return 0;

}
