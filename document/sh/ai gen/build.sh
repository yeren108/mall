#!/bin/bash
# Mall 电商系统 - 应用构建脚本

set -e

# 加载环境变量
if [ -f /opt/mall/config/.env ]; then
    source /opt/mall/config/.env
else
    echo "错误: 环境变量文件不存在，请先复制并配置 /opt/mall/config/.env"
    exit 1
fi

# 配置
VERSION=${VERSION:-"1.0.0"}
REGISTRY=${ALIYUN_REGISTRY:-"registry.cn-shanghai.aliyuncs.com/mall"}
NAMESPACE=${NAMESPACE:-"mall-prod"}

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "Mall 项目构建脚本"
echo "版本: ${VERSION}"
echo "镜像仓库: ${REGISTRY}"
echo "========================================="

# 1. 清理旧构建
echo ""
echo "步骤1: 清理旧构建..."
mvn clean

# 2. 编译打包
echo ""
echo "步骤2: 编译打包 (跳过测试)..."
mvn package -DskipTests -Pprod

# 检查构建结果
if [ ! -f mall-admin/target/mall-admin-1.0-SNAPSHOT.jar ]; then
    echo "错误: mall-admin 构建失败"
    exit 1
fi

if [ ! -f mall-portal/target/mall-portal-1.0-SNAPSHOT.jar ]; then
    echo "错误: mall-portal 构建失败"
    exit 1
fi

if [ ! -f mall-search/target/mall-search-1.0-SNAPSHOT.jar ]; then
    echo "错误: mall-search 构建失败"
    exit 1
fi

# 3. 构建 Docker 镜像
echo ""
echo "步骤3: 构建 Docker 镜像..."

# 创建 Dockerfile 目录
mkdir -p document/sh/dockerfiles

# mall-admin Dockerfile
cat > document/sh/dockerfiles/Dockerfile-admin << EOF
FROM openjdk:8-jdk-alpine
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
ADD mall-admin/target/mall-admin-1.0-SNAPSHOT.jar /app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "/app.jar"]
EOF

# mall-portal Dockerfile
cat > document/sh/dockerfiles/Dockerfile-portal << EOF
FROM openjdk:8-jdk-alpine
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
ADD mall-portal/target/mall-portal-1.0-SNAPSHOT.jar /app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "/app.jar"]
EOF

# mall-search Dockerfile
cat > document/sh/dockerfiles/Dockerfile-search << EOF
FROM openjdk:8-jdk-alpine
RUN apk add --no-cache tzdata && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone
ADD mall-search/target/mall-search-1.0-SNAPSHOT.jar /app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "-Dspring.profiles.active=prod", "/app.jar"]
EOF

# 构建 mall-admin 镜像
echo "构建 mall-admin 镜像..."
docker build -t ${REGISTRY}/mall-admin:${VERSION} -f document/sh/dockerfiles/Dockerfile-admin .
docker tag ${REGISTRY}/mall-admin:${VERSION} ${REGISTRY}/mall-admin:latest

# 构建 mall-portal 镜像
echo "构建 mall-portal 镜像..."
docker build -t ${REGISTRY}/mall-portal:${VERSION} -f document/sh/dockerfiles/Dockerfile-portal .
docker tag ${REGISTRY}/mall-portal:${VERSION} ${REGISTRY}/mall-portal:latest

# 构建 mall-search 镜像
echo "构建 mall-search 镜像..."
docker build -t ${REGISTRY}/mall-search:${VERSION} -f document/sh/dockerfiles/Dockerfile-search .
docker tag ${REGISTRY}/mall-search:${VERSION} ${REGISTRY}/mall-search:latest

# 4. 登录镜像仓库
echo ""
echo "步骤4: 登录镜像仓库..."
if [ -n "$ALIYUN_USERNAME" ] && [ -n "$ALIYUN_PASSWORD" ]; then
    echo "${ALIYUN_PASSWORD}" | docker login --username="${ALIYUN_USERNAME}" --password-stdin ${REGISTRY}
else
    echo "警告: 未配置阿里云镜像仓库凭据，跳过推送步骤"
    echo ""
    echo "========================================="
    echo "本地构建完成！"
    echo "========================================="
    echo ""
    echo "构建的镜像:"
    echo "  - ${REGISTRY}/mall-admin:${VERSION}"
    echo "  - ${REGISTRY}/mall-portal:${VERSION}"
    echo "  - ${REGISTRY}/mall-search:${VERSION}"
    exit 0
fi

# 5. 推送镜像
echo ""
echo "步骤5: 推送镜像到阿里云容器镜像服务..."

docker push ${REGISTRY}/mall-admin:${VERSION}
docker push ${REGISTRY}/mall-admin:latest

docker push ${REGISTRY}/mall-portal:${VERSION}
docker push ${REGISTRY}/mall-portal:latest

docker push ${REGISTRY}/mall-search:${VERSION}
docker push ${REGISTRY}/mall-search:latest

echo ""
echo "========================================="
echo "构建完成！"
echo "========================================="
echo ""
echo "推送的镜像:"
echo "  - ${REGISTRY}/mall-admin:${VERSION}"
echo "  - ${REGISTRY}/mall-portal:${VERSION}"
echo "  - ${REGISTRY}/mall-search:${VERSION}"
echo ""
echo "下一步: 运行部署脚本"
echo "  cd document/sh && ./deploy.sh"
