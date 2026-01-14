#!/bin/bash
# =============================================================================
# Docker 安装脚本（命令行版本）
# 支持: CentOS / RHEL / Ubuntu / Debian
# =============================================================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "========================================="
echo "Docker 安装脚本"
echo "========================================="

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    log_error "无法检测操作系统"
    exit 1
fi

log_info "检测到操作系统: $OS $VERSION"

# 卸载旧版本
log_info "卸载旧版本..."
if command -v apt-get &> /dev/null; then
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
elif command -v yum &> /dev/null; then
    sudo yum remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
elif command -v dnf &> /dev/null; then
    sudo dnf remove -y docker docker-client docker-client-latest docker-common \
        docker-latest docker-latest-logrotate docker-logrotate docker-engine 2>/dev/null || true
fi

# 安装 Docker
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    log_info "在 Ubuntu/Debian 上安装 Docker..."

    # 更新包索引
    sudo apt-get update

    # 安装依赖
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

    # 添加 Docker 官方 GPG 密钥
    if [ "$OS" = "ubuntu" ]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    # 安装 Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ] || [ "$OS" = "rocky" ]; then
    log_info "在 CentOS/RHEL/Rocky 上安装 Docker..."

    # 安装依赖
    if command -v dnf &> /dev/null; then
        sudo dnf -y install dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
    else
        sudo yum install -y yum-utils device-mapper-persistent-data lvm2
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    fi

else
    log_info "使用通用安装脚本..."
    curl -fsSL https://get.docker.com | bash
fi

# 启动 Docker
log_info "启动 Docker 服务..."
if command -v systemctl &> /dev/null; then
    sudo systemctl start docker
    sudo systemctl enable docker
elif command -v service &> /dev/null; then
    sudo service docker start
fi

# 添加当前用户到 docker 组
log_info "添加用户到 docker 组..."
sudo usermod -aG docker $USER

# 配置镜像加速
log_info "配置 Docker 镜像加速..."
sudo mkdir -p /etc/docker

sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

# 重启 Docker
if command -v systemctl &> /dev/null; then
    sudo systemctl restart docker
elif command -v service &> /dev/null; then
    sudo service docker restart
fi

# 安装 Docker Compose
log_info "安装 Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.20.0"

if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
    ARCH="aarch64"
else
    ARCH="x86_64"
fi

sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-${ARCH}" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 验证安装
echo ""
echo "========================================="
echo "安装完成！"
echo "========================================="
echo ""
docker --version
docker-compose --version
echo ""
log_warn "请执行以下命令使 docker 组生效："
echo "  newgrp docker"
echo "  或者重新登录系统"
echo ""
log_info "测试 Docker："
echo "  docker run hello-world"
echo ""
