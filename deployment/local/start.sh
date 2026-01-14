#!/bin/bash
# =============================================================================
# Mall 电商系统 - 本地开发环境启动脚本
# 跨平台支持: Linux / macOS
# =============================================================================

set -e

# 颜色定义
if [[ "$OSTYPE" == "darwin"* ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='\e[0;31m'
    GREEN='\e[0;32m'
    YELLOW='\e[1;33m'
    BLUE='\e[0;34m'
    NC='\e[0m'
fi

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 检测操作系统
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS="Linux"
else
    log_error "不支持的操作系统: $OSTYPE"
    exit 1
fi

log_info "========================================="
log_info "Mall 本地开发环境启动"
log_info "操作系统: $OS"
log_info "========================================="

# 检查 Docker
log_step "检查 Docker..."
if ! command -v docker &> /dev/null; then
    log_error "Docker 未安装"
    log_info "请先安装 Docker Desktop:"
    if [[ "$OS" == "macOS" ]]; then
        log_info "  https://www.docker.com/products/docker-desktop/"
    else
        log_info "  curl -fsSL https://get.docker.com | bash"
    fi
    exit 1
fi
log_info "Docker 已安装: $(docker --version)"

# 检查 Docker Compose
log_step "检查 Docker Compose..."
if ! docker-compose version &> /dev/null && ! docker compose version &> /dev/null; then
    log_error "Docker Compose 未安装"
    exit 1
fi

# 确定使用哪个 compose 命令
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi
log_info "使用: $DOCKER_COMPOSE"

# 检查端口占用
log_step "检查端口占用..."
check_port() {
    local port=$1
    local service=$2
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 || netstat -an 2>/dev/null | grep ":$port.*LISTEN" >/dev/null; then
        log_warn "端口 $port 已被占用 ($service)"
        return 1
    fi
    return 0
}

ports_ok=true
check_port 3306 "MySQL" || ports_ok=false
check_port 6379 "Redis" || ports_ok=false
check_port 5672 "RabbitMQ" || ports_ok=false
check_port 9200 "Elasticsearch" || ports_ok=false
check_port 8080 "mall-admin" || ports_ok=false
check_port 8085 "mall-portal" || ports_ok=false
check_port 8081 "mall-search" || ports_ok=false

if [ "$ports_ok" = false ]; then
    log_warn "部分端口已被占用，可能导致启动失败"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 停止旧容器
log_step "停止旧容器..."
cd "$SCRIPT_DIR"
$DOCKER_COMPOSE down 2>/dev/null || true

# 构建镜像
log_step "构建应用镜像..."
log_info "首次启动可能需要较长时间..."
$DOCKER_COMPOSE build

# 启动服务
log_step "启动服务..."
$DOCKER_COMPOSE up -d

# 等待服务启动
log_step "等待服务启动..."
sleep 10

# 显示状态
log_step "服务状态:"
$DOCKER_COMPOSE ps

# 健康检查
log_step "等待数据库初始化..."
max_wait=60
waited=0
while [ $waited -lt $max_wait ]; do
    if docker exec mall-mysql mysqladmin ping -h localhost -uroot -proot >/dev/null 2>&1; then
        log_info "MySQL 已就绪"
        break
    fi
    sleep 2
    waited=$((waited + 2))
    echo -n "."
done
echo ""

# 初始化数据库（如果需要）
log_step "初始化数据库..."
if [ -f "$SCRIPT_DIR/init.sql" ]; then
    # 检查数据库是否已初始化
    if ! docker exec mall-mysql mysql -uroot -proot -e "USE mall; SHOW TABLES;" >/dev/null 2>&1; then
        log_info "导入数据库..."
        docker exec -i mall-mysql mysql -uroot -proot mall < "$SCRIPT_DIR/init.sql"
        log_info "数据库初始化完成"
    else
        log_info "数据库已初始化，跳过"
    fi
else
    log_warn "数据库脚本不存在: $SCRIPT_DIR/init.sql"
    log_info "请手动导入数据库: ../../document/sql/mall.sql"
fi

echo ""
log_info "========================================="
log_info "启动完成！"
log_info "========================================="
echo ""
echo "访问地址:"
echo "  📊 后台管理 API:       http://localhost:8080"
echo "  🛍️  前台商城 API:        http://localhost:8085"
echo "  🔍 搜索服务 API:        http://localhost:8081"
echo "  📊 Elasticsearch:      http://localhost:9200"
echo "  🐰 RabbitMQ 管理界面:   http://localhost:15672 (mall/mall)"
echo ""
echo "数据库连接:"
echo "  MySQL:   localhost:3306 (root/root)"
echo "  Redis:   localhost:6379 (密码: admin)"
echo "  MongoDB: localhost:27017"
echo ""
echo "查看日志:"
echo "  $DOCKER_COMPOSE logs -f [service]"
echo ""
echo "停止服务:"
echo "  $DOCKER_COMPOSE down"
echo ""
