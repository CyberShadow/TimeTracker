#include <windows.h>
#include <stdio.h>
#include <time.h>

#define WM_ICONNOTIFY (WM_USER+1)

#define ID_TOGGLE 1
#define ID_REPORT 2
#define ID_EXIT 3

HICON iconWork, iconPlay;
HWND hWnd;
BOOL working;
HMENU hMenu;

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

void quit()
{
	if (working)
		toggle();
	
	NOTIFYICONDATA data;
	ZeroMemory(&data, sizeof(data));
	data.cbSize = NOTIFYICONDATA_V1_SIZE;
	data.hWnd = hWnd;
	Shell_NotifyIcon(NIM_DELETE, &data);

	ExitProcess(0);
}

void gen_report()
{
	STARTUPINFO si;
	PROCESS_INFORMATION pi;
	ZeroMemory(&si, sizeof(si));
	si.dwFlags = STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_HIDE;
	if (!CreateProcess(NULL, "GenReport.exe", NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi))
	{
		MessageBox(hWnd, "Failed to run GenReport.exe", "Error", MB_ICONERROR);
		return;
	}
	WaitForSingleObject(pi.hProcess, INFINITE);
	CloseHandle(pi.hProcess);
	CloseHandle(pi.hThread);
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
					quit();
				case WM_RBUTTONDOWN:
					POINT pt;
					GetCursorPos(&pt);
					TrackPopupMenu(hMenu, 0, pt.x, pt.y, 0, hWnd, NULL); 
					break;
			}		
			break;
		case WM_COMMAND:
			switch(LOWORD(wParam))
			{
				case ID_TOGGLE:
					toggle();
					break;
				case ID_REPORT:
					gen_report();
					ShellExecute(hWnd, "open", "report.html", NULL, NULL, SW_SHOW);
					break;
				case ID_EXIT:
					quit();
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

	hMenu = CreatePopupMenu();
	AppendMenu(hMenu, MF_STRING, ID_TOGGLE, "Start/stop work");
	AppendMenu(hMenu, MF_STRING, ID_REPORT, "Generate &report");
	AppendMenu(hMenu, MF_STRING, ID_EXIT, "E&xit");

    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0))
    {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
}
