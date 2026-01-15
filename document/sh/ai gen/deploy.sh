#!/bin/bash
# Mall 电商系统 - 应用部署脚本

set -e

# 加载环境变量
if [ -f /opt/mall/config/.env ]; then
    source /opt/mall/config/.env
else
    echo "错误: 环境变量文件不存在，请先配置 /opt/mall/config/.env"
    exit 1
fi

# 配置
VERSION=${VERSION:-"1.0.0"}
REGISTRY=${ALIYUN_REGISTRY:-"registry.cn-shanghai.aliyuncs.com/mall"}

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_DIR"

echo "========================================="
echo "Mall 项目部署脚本"
echo "版本: ${VERSION}"
echo "========================================="

# 1. 拉取最新镜像
echo ""
echo "步骤1: 拉取最新镜像..."
docker pull ${REGISTRY}/mall-admin:${VERSION}
docker pull ${REGISTRY}/mall-portal:${VERSION}
docker pull ${REGISTRY}/mall-search:${VERSION}

# 2. 停止旧容器
echo ""
echo "步骤2: 停止旧容器..."
if [ -f document/docker/docker-compose-app-prod.yml ]; then
    docker-compose -f document/docker/docker-compose-app-prod.yml down
else
    echo "警告: docker-compose-app-prod.yml 不存在，跳过停止步骤"
fi

# 3. 备份数据库
echo ""
echo "步骤3: 备份数据库..."
BACKUP_DIR="/opt/mall/backup"
mkdir -p ${BACKUP_DIR}
BACKUP_FILE="${BACKUP_DIR}/mall_$(date +%Y%m%d_%H%M%S).sql"

if [ -n "$DB_HOST" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
    echo "备份数据库到: ${BACKUP_FILE}"
    mysqldump -h ${DB_HOST} -u ${DB_USER} -p${DB_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        ${DB_NAME:-mall} > ${BACKUP_FILE}

    # 压缩备份
    gzip ${BACKUP_FILE}
    echo "数据库备份完成: ${BACKUP_FILE}.gz"

    # 上传到 OSS（如果配置了）
    if command -v ossutil &> /dev/null && [ -n "$OSS_BUCKET_NAME" ]; then
        echo "上传备份到 OSS..."
        ossutil cp ${BACKUP_FILE}.gz oss://${OSS_BUCKET_NAME}/backup/
    fi
else
    echo "警告: 未配置数据库连接信息，跳过备份"
fi

# 4. 启动新容器
echo ""
echo "步骤4: 启动新容器..."
if [ -f document/docker/docker-compose-app-prod.yml ]; then
    docker-compose -f document/docker/docker-compose-app-prod.yml up -d
else
    echo "错误: docker-compose-app-prod.yml 不存在"
    exit 1
fi

# 5. 等待应用启动
echo ""
echo "步骤5: 等待应用启动..."
sleep 30

# 6. 健康检查
echo ""
echo "步骤6: 健康检查..."

# 检查函数
check_health() {
    local name=$1
    local port=$2
    local path=$3

    if curl -f -s http://localhost:${port}${path} > /dev/null; then
        echo "  ✓ ${name} 运行正常"
        return 0
    else
        echo "  ✗ ${name} 健康检查失败"
        return 1
    fi
}

# 执行检查
failed=0

check_health "mall-admin" 8080 "/actuator/health" || failed=1
check_health "mall-portal" 8085 "/actuator/health" || failed=1
check_health "mall-search" 8081 "/actuator/health" || failed=1

if [ $failed -eq 1 ]; then
    echo ""
    echo "警告: 部分应用健康检查失败，请检查日志"
    echo "查看日志: docker-compose -f document/docker/docker-compose-app-prod.yml logs"
    exit 1
fi

echo ""
echo "========================================="
echo "部署完成！"
echo "========================================="
echo ""
echo "应用状态:"
docker-compose -f document/docker/docker-compose-app-prod.yml ps
echo ""
echo "查看日志:"
echo "  docker-compose -f document/docker/docker-compose-app-prod.yml logs -f [service]"
echo ""
echo "访问地址（需要先配置 Nginx）:"
echo "  后台管理: https://admin.yourdomain.com"
echo "  前台商城: https://www.yourdomain.com"
echo "  API: https://api.yourdomain.com"
