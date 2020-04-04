call "%VS142%\VC\Auxiliary\Build\vcvars64.bat"
cd ../bin
dumpbin /exports %cd%\bootstrap.dll
PAUSE