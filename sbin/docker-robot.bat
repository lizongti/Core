docker network create slots-network
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest
docker stop slots-game-robot
docker rm slots-game-robot
docker run -e PRO_SPEC_T=docker-local --network slots-network --privileged=true ^
--name slots-game-robot --hostname slots-game-robot ^
-v %cd%/../:/project -w /project/bin -it --rm ^
registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-game:latest robot
PAUSE
