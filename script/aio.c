// #include<stdio.h>
// #include<time.h>
// int main (){
//     struct tm timep;
//     timep.tm_year = 1970-1900;
//     timep.tm_mon = 1-1;
//     timep.tm_mday = 1;
//     timep.tm_hour = 8;
//     timep.tm_min = 0;
//     timep.tm_sec = 0;
//     timep.tm_isdst = 0;
//     long int ans = mktime(&timep);
//     printf("%ld",ans);

//     return 0;
// }


#include <stdio.h>
#include <time.h>
int main()
{
	struct timespec time1 = {0, 0};
	clock_gettime(CLOCK_REALTIME, &time1);
	printf("CLOCK_REALTIME: %ld, %ld\n", time1.tv_sec, time1.tv_nsec);
	clock_gettime(CLOCK_MONOTONIC, &time1);
	printf("CLOCK_MONOTONIC: %ld, %ld\n", time1.tv_sec, time1.tv_nsec);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &time1);
	printf("CLOCK_PROCESS_CPUTIME_ID: %ld, %ld\n", time1.tv_sec, time1.tv_nsec);
	clock_gettime(CLOCK_THREAD_CPUTIME_ID, &time1);
	printf("CLOCK_THREAD_CPUTIME_ID: %ld, %ld\n", time1.tv_sec, time1.tv_nsec);
	printf("\n%ld\n", time(NULL));
	// sleep(1);
}