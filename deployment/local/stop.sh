#!/bin/bash
# =============================================================================
# Mall 电商系统 - 停止服务脚本
# 跨平台支持: Linux / macOS
# =============================================================================

# 颜色定义
if [[ "$OSTYPE" == "darwin"* ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='\e[0;31m'
    GREEN='\e[0;32m'
    YELLOW='\e[1;33m'
    NC='\e[0m'
fi

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 确定使用哪个 compose 命令
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "========================================="
echo "停止 Mall 服务"
echo "========================================="
echo ""

# 询问是否保留数据
read -p "是否保留数据卷? (Y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    log_info "停止服务并删除数据..."
    $DOCKER_COMPOSE down -v
else
    log_info "停止服务（保留数据）..."
    $DOCKER_COMPOSE down
fi

echo ""
log_info "服务已停止"
echo ""
echo "重新启动请运行:"
if [[ "$OSTYPE" == "darwin"* ]] || [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "  ./start.sh"
else
    echo "  start.bat"
fi
