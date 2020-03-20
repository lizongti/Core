cd ..
docker pull registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-base:cmake
docker run -v %cd%:/project -e CMAKE_BINARY_DIR=/project/bin --rm registry.cn-hangzhou.aliyuncs.com/vr-cat/slots-base:cmake
PAUSE