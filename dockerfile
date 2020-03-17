FROM registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-base:server

COPY bin/Server /project/bin/Server
COPY Config /project/Config
COPY Source/Lua /project/Source/Lua

RUN ln -snf /usr/share/zoneinfo/America/New_York /etc/localtime && echo America/New_York > /etc/timezone && \
    chmod -R 755 /project

##    find /project/Source/Lua -name "*.lua" |xargs -I {} luajit -b {} {} && \ 
## luajit 编译模式没有错误的代码行

WORKDIR /project/bin

ENTRYPOINT ["./Server"]

