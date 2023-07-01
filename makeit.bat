ml64.exe /I /Zp16 /nologo /Cp /Zd /Zi /c src.asm >> src_err.txt
rc.exe /r src.rc
link.exe /nologo /LIBPATH: /MACHINE:X64 /SUBSYSTEM:WINDOWS /entry:WinMain src.obj src.res