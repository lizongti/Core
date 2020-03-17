docker network create slots-network
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest
docker stop slots-game-dispatcher
docker rm slots-game-dispatcher
docker run -e PRO_SPEC_T=docker-local --network slots-network --privileged=true ^
--name slots-game-dispatcher --hostname slots-game-dispatcher -p 10000:10000 ^
-v %cd%/../:/project -w /project/bin -it --rm ^
registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest dispatcher0
PAUSE
