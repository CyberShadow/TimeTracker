#include <windows.h>
#include <tchar.h>
#include <stdio.h>
#include <time.h>

#define WM_ICONNOTIFY (WM_USER+1)

HICON iconWork, iconPlay;
HWND hWnd;
BOOL working;

void toggle()
{
	working = !working;

	time_t t;
	time(&t);
	char* timestr = ctime(&t);
	timestr[strlen(timestr)-1] = 0;
	FILE* f = fopen("worklog.txt", "at");
	fprintf(f, "[%s] Work %s\n", timestr, working ? "started" : "stopped");
	fclose(f);
	
	NOTIFYICONDATA data;
	ZeroMemory(&data, sizeof(data));
	data.cbSize = NOTIFYICONDATA_V1_SIZE;
	data.hWnd = hWnd;
	data.uFlags = NIF_ICON;
	data.hIcon = working ? iconWork : iconPlay;
	Shell_NotifyIcon(NIM_MODIFY, &data);
}

LRESULT CALLBACK WndProc(HWND hWnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	switch (uMsg)
	{
		case WM_ICONNOTIFY:
			switch(lParam)
			{
				case WM_LBUTTONDOWN:
					toggle();
					break;
				case WM_MBUTTONDOWN:
					if (working)
						toggle();
					ExitProcess(0);
			}
			break;
	}

	return DefWindowProc(hWnd, uMsg, wParam, lParam);
}

void main()
{
	HINSTANCE hInstance = GetModuleHandle(NULL);
	iconWork = (HICON)LoadImage(NULL, TEXT("work.ico"), IMAGE_ICON, 16, 16, LR_LOADFROMFILE);
	iconPlay = (HICON)LoadImage(NULL, TEXT("play.ico"), IMAGE_ICON, 16, 16, LR_LOADFROMFILE);

	working = false;

	WNDCLASSEX wcx;
	wcx.cbSize = sizeof(wcx);
	wcx.style = 0;
	wcx.lpfnWndProc = WndProc;
	wcx.cbClsExtra = 0;
	wcx.cbWndExtra = 0;
	wcx.hInstance = hInstance;
	wcx.hIcon = NULL;
	wcx.hCursor = NULL;
	wcx.hbrBackground = NULL;
	wcx.lpszMenuName = NULL;
	wcx.lpszClassName = "TimeTracker";
	wcx.hIconSm = NULL;

	ATOM cls = RegisterClassEx(&wcx);
	hWnd = CreateWindowEx(0, wcx.lpszClassName, "TimeTracker", 0, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, HWND_MESSAGE, NULL, hInstance, NULL);
	
	NOTIFYICONDATA data;
	ZeroMemory(&data, sizeof(data));
	data.cbSize = NOTIFYICONDATA_V1_SIZE;
	data.hWnd = hWnd;
	data.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
	data.uCallbackMessage = WM_ICONNOTIFY;
	data.hIcon = iconPlay;
	strcpy(data.szTip, "TimeTracker");

	Shell_NotifyIcon(NIM_ADD, &data);

    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}
