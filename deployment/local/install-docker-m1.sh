#!/bin/bash
# =============================================================================
# Docker 安装脚本 - Apple Silicon (M1/M2/M3)
# 使用 Colima 轻量级方案
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_step() {
    echo -e "${BLUE}==>${NC} $1"
}

echo "========================================="
echo "Docker 安装 - Apple Silicon"
echo "========================================="
echo ""
echo "预计流量: ~210MB"
echo "预计时间: 5-10 分钟"
echo ""

# 检查架构
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
    echo "警告: 这不是 Apple Silicon Mac ($ARCH)"
    read -p "是否继续? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 1. 检查/安装 Homebrew
log_step "检查 Homebrew..."
if command -v brew &> /dev/null; then
    log_info "Homebrew 已安装: $(brew --version | head -1)"
else
    log_info "安装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 配置 Homebrew 环境变量
    log_step "配置 Homebrew..."
    if [ -n "$ZSH_VERSION" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -n "$BASH_VERSION" ]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.bash_profile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
fi

# 2. 安装 Docker 组件
log_step "安装 Colima 和 Docker..."
brew install colima docker docker-compose

# 3. 验证安装
log_step "验证安装..."
colima version
docker --version
docker-compose version

# 4. 启动 Colima
log_step "启动 Colima (4CPU 8GB 60GB)..."
if colima status &> /dev/null; then
    log_info "Colima 已在运行"
else
    colima start --cpu 4 --memory 8 --disk 60
fi

# 5. 测试 Docker
log_step "测试 Docker..."
docker run --rm hello-world

# 6. 显示信息
echo ""
echo "========================================="
echo "安装完成！"
echo "========================================="
echo ""
echo "版本信息:"
echo "  Colima:   $(colima version | head -1)"
echo "  Docker:   $(docker --version)"
echo "  Compose:  $(docker-compose version)"
echo ""
echo "架构: $ARCH (Apple Silicon)"
echo ""
echo "Colima 常用命令:"
echo "  colima start    # 启动"
echo "  colima stop     # 停止"
echo "  colima status   # 状态"
echo "  colima ssh      # SSH 进入"
echo ""
echo "下一步:"
echo "  cd /Users/jacobx/Downloads/openCodeDemo1/mall/deployment/local"
echo "  ./start.sh"
echo ""
