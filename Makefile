TimeTracker.exe : TimeTracker.obj
	link /nologo /ENTRY:main /NODEFAULTLIB /SUBSYSTEM:WINDOWS TimeTracker.obj user32.lib gdi32.lib shell32.lib msvcrt.lib kernel32.lib
TimeTracker.obj : TimeTracker.cpp
	cl /nologo /c /O1 /GS- TimeTracker.cpp
