#!/bin/bash
# =============================================================================
# Mall 电商系统 - 部署脚本 (2核4G 优化版)
# =============================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "========================================="
log_info "Mall 电商系统部署脚本"
log_info "========================================="

# 检查 Docker
log_info "检查 Docker..."
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装，请先运行: ./setup-swap.sh"
    exit 1
fi

# 检查 Docker Compose
log_info "检查 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose 未安装"
    exit 1
fi

# 检查环境变量文件
log_info "检查环境变量文件..."
if [ ! -f "$PROJECT_DIR/.env" ]; then
    log_error ".env 文件不存在"
    log_info "请先复制并配置环境变量:"
    log_info "  cp .env.example .env"
    log_info "  vi .env"
    exit 1
fi

# 加载环境变量
source "$PROJECT_DIR/.env"

# 检查必需的环境变量
log_info "验证环境变量..."
required_vars=("DB_PASSWORD" "DB_ROOT_PASSWORD" "REDIS_PASSWORD" "JWT_SECRET")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ] || [[ "${!var}" =~ ^Change ]]; then
        log_error "环境变量 $var 未设置或使用默认值"
        log_info "请编辑 .env 文件并设置正确的值"
        exit 1
    fi
done

# 检查 Swap
log_info "检查 Swap..."
SWAP_SIZE=$(free -m | awk '/^Swap:/ {print $2}')
if [ "$SWAP_SIZE" -eq 0 ]; then
    log_warn "Swap 未配置"
    log_info "建议配置 Swap 以避免内存不足"
    read -p "是否现在配置 Swap? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        bash "$SCRIPT_DIR/setup-swap.sh"
    fi
else
    log_info "Swap 已配置: ${SWAP_SIZE}MB"
fi

# 创建数据目录
log_info "创建数据目录..."
mkdir -p "${DATA_DIR:-/opt/mall}"/{data,logs,config}
mkdir -p "${DATA_DIR:-/opt/mall}/data"/{mysql,redis,mongo,rabbitmq,elasticsearch}
mkdir -p "${DATA_DIR:-/opt/mall}/logs"/{mall-admin,mall-portal,mall-search}
mkdir -p /var/log/{mysql,mongodb}

# 设置权限
log_info "设置目录权限..."
chmod -R 755 "${DATA_DIR:-/opt/mall}"

# 停止旧容器（如果存在）
log_info "停止旧容器..."
cd "$PROJECT_DIR"
docker-compose down 2>/dev/null || true

# 拉取镜像
log_info "拉取 Docker 镜像..."
docker-compose pull

# 启动服务
log_info "启动服务..."
docker-compose up -d

# 等待服务启动
log_info "等待服务启动..."
sleep 30

# 初始化数据库
log_info "初始化数据库..."
if [ -f "$PROJECT_DIR/../../document/sql/mall.sql" ]; then
    log_info "导入数据库..."
    docker exec -i mall-mysql mysql -u root -p"${DB_ROOT_PASSWORD}" mall < "$PROJECT_DIR/../../document/sql/mall.sql"
    log_info "数据库导入完成"
else
    log_warn "数据库文件不存在: $PROJECT_DIR/../../document/sql/mall.sql"
    log_info "请手动导入数据库"
fi

# 健康检查
log_info "执行健康检查..."
check_health() {
    local name=$1
    local port=$2
    local path=${3:-/actuator/health}

    if curl -f -s http://localhost:${port}${path} > /dev/null 2>&1; then
        log_info "  ✓ $name 运行正常"
        return 0
    else
        log_error "  ✗ $name 健康检查失败"
        return 1
    fi
}

# 检查各个服务
failed=0
check_health "mall-admin" 8080 || failed=1
check_health "mall-portal" 8085 || failed=1
check_health "mall-search" 8081 || failed=1

# 显示状态
echo ""
log_info "服务状态:"
docker-compose ps

echo ""
log_info "========================================="
if [ $failed -eq 0 ]; then
    log_info "部署成功！"
else
    log_warn "部分服务健康检查失败，请查看日志"
fi
log_info "========================================="
echo ""
echo "查看日志:"
echo "  docker-compose logs -f [service]"
echo ""
echo "查看内存使用:"
echo "  docker stats"
echo "  free -h"
echo ""
echo "访问地址:"
echo "  后台管理 API: http://localhost:8080"
echo "  前台商城 API: http://localhost:8085"
echo "  搜索服务 API: http://localhost:8081"
echo "  Elasticsearch: http://localhost:9200"
echo "  RabbitMQ 管理界面: http://localhost:15672"
echo ""
echo "默认账号:"
echo "  RabbitMQ: ${MQ_USER} / ${MQ_PASSWORD}"
echo ""
