docker stop slots-game-dispatcher
docker stop slots-game-schedule
docker stop slots-game-robot
docker stop slots-game-manager
docker stop slots-game-notification
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-base:cmake
docker run -v %cd%/../:/project -e CMAKE_BINARY_DIR=/project/bin --rm registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-base:cmake
PAUSE