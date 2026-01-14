#!/bin/bash
# =============================================================================
# M1/M2/M3 Mac Docker 完整安装脚本
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo "========================================="
echo "M1/M2/M3 Mac Docker 安装"
echo "========================================="
echo ""
echo "请选择安装方式："
echo ""
echo "1) Docker Desktop (官方桌面版，推荐)"
echo "2) Colima (命令行版，轻量级)"
echo ""
read -p "请输入选项 (1/2): " choice

if [ "$choice" = "1" ]; then
    echo ""
    log_info "你选择了 Docker Desktop"
    echo ""
    echo "正在下载 Docker Desktop for Mac (Apple Silicon)..."
    echo "下载地址: https://desktop.docker.com/mac/main/arm64/Docker.dmg"
    echo ""
    echo "如果浏览器没有自动打开，请手动复制上面的地址下载"
    echo ""

    # 尝试打开浏览器下载
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "https://desktop.docker.com/mac/main/arm64/Docker.dmg"
        log_info "已在浏览器中打开下载链接"
    fi

    echo ""
    echo "下载完成后，请执行以下步骤："
    echo ""
    echo "1. 双击下载的 Docker.dmg 文件"
    echo "2. 拖动 Docker 图标到 Applications 文件夹"
    echo "3. 打开 Docker.app"
    echo "4. 等待 Docker 启动（菜单栏会出现 Docker 图标）"
    echo "5. 配置镜像加速："
    echo "   - 点击 Docker 图标 -> Settings -> Docker Engine"
    echo "   - 添加以下配置："
    echo ''
    echo '   {'
    echo '     "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]'
    echo '   }'
    echo ''
    echo "   - 点击 'Apply & Restart'"
    echo ""
    echo "6. 验证安装："
    echo "   docker --version"
    echo "   docker run hello-world"
    echo ""

elif [ "$choice" = "2" ]; then
    echo ""
    log_info "你选择了 Colima"
    echo ""

    # 检查 Homebrew
    if ! command -v brew &> /dev/null; then
        log_warn "Homebrew 未安装，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    # 安装 Colima 和 Docker
    log_info "安装 Colima 和 Docker..."
    brew install colima docker docker-compose

    # 删除旧配置
    log_info "清理旧配置..."
    colima stop 2>/dev/null || true
    colima delete 2>/dev/null || true
    rm -rf ~/.colima ~/.lima ~/.docker

    # 创建配置文件
    log_info "配置 Docker 镜像加速..."
    mkdir -p ~/.docker
    cat > ~/.docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF

    # 启动 Colima
    log_info "启动 Colima (4CPU 8GB)..."
    colima start --cpu 4 --memory 8

    # 验证
    echo ""
    log_info "验证安装..."
    docker --version
    docker run hello-world

    echo ""
    log_info "Colima 安装完成！"
    echo ""
    echo "Colima 常用命令："
    echo "  colima start    # 启动"
    echo "  colima stop     # 停止"
    echo "  colima status   # 状态"
    echo "  colima ssh      # SSH 进入"

else
    echo ""
    log_warn "无效选项"
    exit 1
fi

echo ""
echo "========================================="
echo "下一步：启动 Mall 项目"
echo "========================================="
echo ""
echo "cd /Users/jacobx/Downloads/openCodeDemo1/mall/deployment/local"
echo "./start.sh"
echo ""
