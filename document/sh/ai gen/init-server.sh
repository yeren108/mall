#!/bin/bash
# Mall 电商系统 - 服务器初始化脚本
# 适用于: CentOS 7+ / Ubuntu 20.04+

set -e

echo "========================================="
echo "Mall 服务器初始化"
echo "========================================="

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统"
    exit 1
fi

echo "检测到操作系统: $OS"

# 更新系统
echo "步骤1: 更新系统..."
if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum update -y
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt update && apt upgrade -y
fi

# 安装 Docker
echo "步骤2: 安装 Docker..."
curl -fsSL https://get.docker.com | bash -s docker
systemctl start docker
systemctl enable docker

# 安装 Docker Compose
echo "步骤3: 安装 Docker Compose..."
DOCKER_COMPOSE_VERSION="2.20.0"
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 验证安装
docker --version
docker-compose --version

# 安装 JDK 8
echo "步骤4: 安装 JDK 8..."
if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt install -y openjdk-8-jdk
fi

# 验证安装
java -version

# 安装 Maven
echo "步骤5: 安装 Maven..."
if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum install -y maven
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt install -y maven
fi

# 安装 Nginx
echo "步骤6: 安装 Nginx..."
if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum install -y nginx
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt install -y nginx
fi

# 创建应用目录
echo "步骤7: 创建应用目录..."
mkdir -p /opt/mall/{app,logs,backup,config,scripts}
mkdir -p /data/nginx/{html,conf,logs}

# 配置防火墙
echo "步骤8: 配置防火墙..."
if [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=22/tcp
        firewall-cmd --reload
    fi
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    if command -v ufw &> /dev/null; then
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw allow 22/tcp
        ufw --force enable
    fi
fi

# 设置时区
echo "步骤9: 设置时区..."
timedatectl set-timezone Asia/Shanghai

# 优化系统参数
echo "步骤10: 优化系统参数..."
cat >> /etc/sysctl.conf << EOF
# 网络优化
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 文件描述符
fs.file-max = 655350
EOF

sysctl -p

# 配置文件描述符限制
cat >> /etc/security/limits.conf << EOF
* soft nofile 655350
* hard nofile 655350
EOF

# 创建环境变量模板
echo "步骤11: 创建环境变量模板..."
cat > /opt/mall/config/.env.example << 'EOF'
# 数据库配置
DB_HOST=your-rds-endpoint
DB_PORT=3306
DB_NAME=mall
DB_USER=mall_app
DB_PASSWORD=your-strong-password

# Redis 配置
REDIS_HOST=your-redis-endpoint
REDIS_PORT=6379
REDIS_PASSWORD=your-redis-password
REDIS_DATABASE=0

# MongoDB 配置
MONGO_HOST=your-mongo-endpoint
MONGO_PORT=27017
MONGO_DATABASE=mall-port
MONGO_USER=mall_app
MONGO_PASSWORD=your-mongo-password

# RabbitMQ 配置
MQ_HOST=your-mq-endpoint
MQ_PORT=5672
MQ_VHOST=/mall
MQ_USER=mall_app
MQ_PASSWORD=your-mq-password

# JWT 配置
JWT_SECRET=your-64-character-random-secret-key

# 阿里云 OSS 配置
OSS_ENDPOINT=oss-cn-shanghai.aliyuncs.com
OSS_ACCESS_KEY_ID=your-access-key-id
OSS_ACCESS_KEY_SECRET=your-access-key-secret
OSS_BUCKET_NAME=mall-prod

# 阿里云镜像仓库
ALIYUN_REGISTRY=registry.cn-shanghai.aliyuncs.com
ALIYUN_USERNAME=your-username
ALIYUN_PASSWORD=your-password
EOF

echo ""
echo "========================================="
echo "服务器初始化完成！"
echo "========================================="
echo ""
echo "下一步操作:"
echo "1. 复制环境变量模板: cp /opt/mall/config/.env.example /opt/mall/config/.env"
echo "2. 编辑环境变量: vi /opt/mall/config/.env"
echo "3. 上传项目代码到服务器"
echo "4. 运行构建脚本: cd /opt/mall/document/sh && ./build.sh"
echo "5. 运行部署脚本: cd /opt/mall/document/sh && ./deploy.sh"
echo ""
