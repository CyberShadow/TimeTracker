#include <windows.h>
#include <stdio.h>
#include <time.h>

void main()
{
	char* cmdline = GetCommandLine();

	if (*cmdline=='"')
		do ; while(*++cmdline != '"');
	do ; while(*++cmdline != ' ' && *cmdline != 0);
	if (*cmdline == 0)
	{
		printf("No task specified\n");
		return;
	}
	cmdline++;

	time_t t;
	time(&t);
	char* timestr = ctime(&t);
	timestr[strlen(timestr)-1] = 0;
	FILE* f = fopen("worklog.txt", "at");
	fprintf(f, "[%s] Task: %s\n", timestr, cmdline);
	fclose(f);
}
