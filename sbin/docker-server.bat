cd ..
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest
docker run -e PRO_SPEC_T=docker-local --privileged=true ^
--name Core --hostname Core -p 10000:10000 ^
-v %cd%:/project -w /project/bin -it --rm ^
registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest -t 2 boot
PAUSE
