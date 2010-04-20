.cpp.obj:
	cl /nologo /c /O1 /GS- $*.cpp
all: TimeTracker.exe WorkOn.exe
TimeTracker.exe : TimeTracker.obj
	link /nologo /ENTRY:main /NODEFAULTLIB /SUBSYSTEM:WINDOWS TimeTracker.obj user32.lib gdi32.lib shell32.lib msvcrt.lib kernel32.lib
WorkOn.exe : WorkOn.obj
	link /nologo /ENTRY:main /NODEFAULTLIB /SUBSYSTEM:CONSOLE WorkOn.obj kernel32.lib msvcrt.lib
