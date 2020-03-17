rem 切换到.proto协议所在的目录
cd  .
rem 将当前文件夹中的所有协议文件转换为lua文件
protoc.exe --plugin=protoc-gen-lua=protoc-gen-lua.bat --lua_out=../../Lua/Protocol FeverCardMessage.proto

echo end
pause