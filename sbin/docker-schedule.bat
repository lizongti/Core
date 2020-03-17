docker network create slots-network
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest
docker stop slots-game-schedule
docker rm slots-game-schedule
docker run -e PRO_SPEC_T=docker-local --network slots-network --privileged=true ^
--name slots-game-schedule --hostname slots-game-schedule ^
-v %cd%/../:/project -w /project/bin -it --rm ^
registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest schedule
PAUSE
