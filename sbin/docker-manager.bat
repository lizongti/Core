docker network create slots-network
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest
docker stop slots-game-manager
docker rm slots-game-manager
docker run -e PRO_SPEC_T=docker-local --network slots-network --privileged=true ^
--name slots-game-manager --hostname slots-game-manager -p 18800:18800 ^
-v %cd%/../:/project -w /project/bin -it --rm ^
registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest manager
PAUSE
