del /f /s /q ..\..\HotResources\LuaScript\protocol\*.*
for /r "." %%i in (*.proto) do ..\..\..\protobuf-2.4.1\src\protoc.exe --lua_out=../../HotResources/LuaScript/protocol/ --plugin=protoc-gen-lua="..\..\..\protoc-gen-lua\plugin\protoc-gen-lua.bat" %%~nxi
pause
