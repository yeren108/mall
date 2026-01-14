# Mall 2核4G 全功能优化部署方案

## 方案概述

| 项目 | 配置 |
|------|------|
| 服务器 | 2核4G |
| 年成本 | ¥299（新用户3年）→ 续费 ¥1500/年 |
| 月均 | ¥46（首年）→ ¥125（续费） |
| 功能 | 全功能（含 Elasticsearch） |

---

## 一、内存分配优化方案

### 内存占用分析

| 服务 | 默认占用 | 优化后 | 优化措施 |
|------|----------|--------|----------|
| **mall-admin** | 512MB | **350MB** | -Xms350m -Xmx350m |
| **mall-portal** | 768MB | **500MB** | -Xms500m -Xmx500m |
| **mall-search** | 256MB | **200MB** | -Xms200m -Xmx200m |
| **MySQL** | 1GB | **700MB** | innodb_buffer_pool=500M |
| **Redis** | 200MB | **150MB** | maxmemory=150mb |
| **MongoDB** | 500MB | **300MB** | cacheSizeGB=0.3 |
| **RabbitMQ** | 300MB | **200MB** | 减少并发数 |
| **Elasticsearch** | 2GB | **800MB** | 关键优化！ |
| **Nginx** | 50MB | **50MB** | |
| **系统** | 500MB | **500MB** | |
| **合计** | ~5.4GB | **~3.75GB** | ✅ 可运行 |

### 关键：Elasticsearch 优化

Elasticsearch 是内存大户，需要特别优化：

```yaml
# elasticsearch.yml
cluster.name: "mall-cluster"
node.name: "mall-node-1"

# 内存锁（防止 swap）
bootstrap.memory_lock: false

# 单节点模式
discovery.type: single-node

# 索引优化
index.number_of_shards: 1
index.number_of_replicas: 0

# 内存设置（ES 会自动分配堆大小的 50% 给 JVM）
# 这里我们限制 ES 总内存使用
```

```bash
# ES JVM 配置
-Xms800m
-Xmx800m

# 禁用一些功能节省内存
-Xmn256m
-XX:+UseG1GC
```

---

## 二、Docker Compose 配置（优化版）

### 文件：docker-compose-full-optimized.yml

```yaml
version: '3.8'

services:
  # ==================== 应用服务 ====================

  mall-admin:
    image: ${REGISTRY:-registry.cn-shanghai.aliyuncs.com/mall}/mall-admin:${VERSION:-latest}
    container_name: mall-admin
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JAVA_OPTS=-Xms350m -Xmx350m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
      - DB_HOST=${DB_HOST}
      - DB_PORT=3306
      - DB_NAME=mall
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - /opt/mall/logs/mall-admin:/var/logs
    restart: unless-stopped
    depends_on:
      - mysql
      - redis
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 400M

  mall-portal:
    image: ${REGISTRY:-registry.cn-shanghai.aliyuncs.com/mall}/mall-portal:${VERSION:-latest}
    container_name: mall-portal
    ports:
      - "8085:8085"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JAVA_OPTS=-Xms500m -Xmx500m -XX:+UseG1GC -XX:MaxGCPauseMillis=200
      - DB_HOST=${DB_HOST}
      - DB_PORT=3306
      - DB_NAME=mall
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - MONGO_HOST=mongo
      - MONGO_PORT=27017
      - MONGO_DATABASE=mall-port
      - MONGO_USER=${MONGO_USER}
      - MONGO_PASSWORD=${MONGO_PASSWORD}
      - MQ_HOST=rabbitmq
      - MQ_PORT=5672
      - MQ_VHOST=/mall
      - MQ_USER=${MQ_USER}
      - MQ_PASSWORD=${MQ_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
    volumes:
      - /opt/mall/logs/mall-portal:/var/logs
    restart: unless-stopped
    depends_on:
      - mysql
      - redis
      - mongo
      - rabbitmq
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 600M

  mall-search:
    image: ${REGISTRY:-registry.cn-shanghai.aliyuncs.com/mall}/mall-search:${VERSION:-latest}
    container_name: mall-search
    ports:
      - "8081:8081"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JAVA_OPTS=-Xms200m -Xmx200m -XX:+UseG1GC
      - DB_HOST=${DB_HOST}
      - DB_PORT=3306
      - DB_NAME=mall
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - ES_HOST=elasticsearch
      - ES_PORT=9200
    volumes:
      - /opt/mall/logs/mall-search:/var/logs
    restart: unless-stopped
    depends_on:
      - mysql
      - redis
      - elasticsearch
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 300M

  # ==================== 数据库服务 ====================

  mysql:
    image: mysql:5.7
    container_name: mall-mysql
    ports:
      - "3306:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=${DB_ROOT_PASSWORD}
      - MYSQL_DATABASE=mall
      - MYSQL_USER=${DB_USER}
      - MYSQL_PASSWORD=${DB_PASSWORD}
      - TZ=Asia/Shanghai
    volumes:
      - /opt/mall/data/mysql:/var/lib/mysql
      - /opt/mall/config/mysql/my.cnf:/etc/mysql/conf.d/my.cnf:ro
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_general_ci
      - --default-time-zone=+08:00
      - --max_connections=100
      - --innodb_buffer_pool_size=500M
    restart: unless-stopped
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 800M

  redis:
    image: redis:7-alpine
    container_name: mall-redis
    ports:
      - "6379:6379"
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --maxmemory 150mb
      --maxmemory-policy allkeys-lru
      --save 900 1
      --save 300 10
      --save 60 10000
    volumes:
      - /opt/mall/data/redis:/data
    restart: unless-stopped
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 200M

  mongo:
    image: mongo:4.4
    container_name: mall-mongo
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_DATABASE=mall-port
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD}
    volumes:
      - /opt/mall/data/mongo:/data/db
      - /opt/mall/config/mongo/mongod.conf:/etc/mongod.conf:ro
    command: --config /etc/mongod.conf --wiredTigerCacheSizeGB 0.3
    restart: unless-stopped
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 400M

  # ==================== 中间件服务 ====================

  rabbitmq:
    image: rabbitmq:3.11-management-alpine
    container_name:mall-rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=${MQ_USER}
      - RABBITMQ_DEFAULT_PASS=${MQ_PASSWORD}
      - RABBITMQ_DEFAULT_VHOST=/mall
    volumes:
      - /opt/mall/data/rabbitmq:/var/lib/rabbitmq
    restart: unless-stopped
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 300M

  elasticsearch:
    image: elasticsearch:7.17.3
    container_name: mall-elasticsearch
    ports:
      - "9200:9200"
      - "9300:9300"
    environment:
      - discovery.type=single-node
      - ES_JAVA_OPTS=-Xms800m -Xmx800m -Xmn256m
      - cluster.name=mall-cluster
      - node.name=mall-node-1
      - bootstrap.memory_lock=false
      - indices.memory.index_buffer_size=50mb
      - indices.memory.min_index_buffer_size=10mb
      - thread_pool.write.queue_size=500
      - thread_pool.search.queue_size=500
    volumes:
      - /opt/mall/data/elasticsearch:/usr/share/elasticsearch/data
      - /opt/mall/config/elasticsearch/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml:ro
    restart: unless-stopped
    networks:
      - mall-network
    deploy:
      resources:
        limits:
          memory: 900M

networks:
  mall-network:
    driver: bridge
```

---

## 三、优化配置文件

### MySQL 优化配置

**文件：/opt/mall/config/mysql/my.cnf**

```ini
[mysqld]
# 基础配置
port = 3306
character-set-server = utf8mb4
collation-server = utf8mb4_general_ci
default-time-zone = '+08:00'

# 连接配置
max_connections = 100
max_connect_errors = 1000

# 内存配置（4G 总内存，MySQL 分配 700MB）
innodb_buffer_pool_size = 500M
key_buffer_size = 64M
table_open_cache = 200
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 2M
myisam_sort_buffer_size = 4M

# InnoDB 配置
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 8M
innodb_log_file_size = 64M

# 查询缓存
query_cache_size = 32M
query_cache_type = 1

# 日志配置
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

# 二进制日志
log_bin = /var/lib/mysql/mysql-bin
expire_logs_days = 7
max_binlog_size = 100M

[client]
default-character-set = utf8mb4
```

### MongoDB 优化配置

**文件：/opt/mall/config/mongo/mongod.conf**

```yaml
storage:
  dbPath: /data/db
  journal:
    enabled: true
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.3
      journalCompressor: snappy
    collectionConfig:
      blockCompressor: snappy
    indexConfig:
      prefixCompression: true

systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true
  logRotate: reopen

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

processManagement:
  fork: false
```

### Elasticsearch 优化配置

**文件：/opt/mall/config/elasticsearch/elasticsearch.yml**

```yaml
cluster.name: "mall-cluster"
node.name: "mall-node-1"

# 单节点模式
discovery.type: single-node

# 网络配置
network.host: 0.0.0.0
http.port: 9200

# 内存锁（低内存禁用）
bootstrap.memory_lock: false

# 索引优化
index.number_of_shards: 1
index.number_of_replicas: 0
index.codec: best_compression

# 查询优化
indices.queries.cache.size: 10%
indices.requests.cache.size: 5%

# 字段缓存
indices.fielddata.cache.size: 15%

# 线程池优化
thread_pool:
  write:
    queue_size: 500
  search:
    queue_size: 500

# 路由优化
cluster.routing.allocation.disk.threshold_enabled: false
```

---

## 四、免费对象存储方案

### UCloud US3（推荐）

**免费额度：**
- 存储空间：5GB
- 公网流量：2GB/月
- 请求次数：100万次/月

**申请地址：** https://www.ucloud.cn/

**配置方式：**

```yaml
# application-prod.yml
ucloud:
  us3:
    endpoint: https://cn-bj.ufileos.com  # 北京节点
    bucketName: mall-prod
    publicKey: ${US3_PUBLIC_KEY}
    privateKey: ${US3_PRIVATE_KEY}
    # 或使用兼容 S3 的 API
    s3:
      endpoint: https://cn-bj.ufileos.com
      accessKey: ${US3_ACCESS_KEY}
      secretKey: ${US3_SECRET_KEY}
      bucketName: mall-prod
```

**其他免费对象存储选项：**

| 服务商 | 免费额度 | 优势 |
|--------|----------|------|
| **UCloud US3** | 5GB + 2GB流量 | 国内访问快 |
| 七牛云 | 10GB + 10GB流量 | CDN 加速好 |
| 又拍云 | 10GB + 15GB流量 | 有免费 SSL |
| 阿里云 OSS | 新用户 3个月5GB | 需要绑定域名 |

---

## 五、Swap 配置（关键优化）

由于 4GB 内存跑全功能比较紧张，建议配置 Swap：

```bash
# 创建 2GB Swap 文件
dd if=/dev/zero of=/swapfile bs=1M count=2048
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# 设置开机自动挂载
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 设置 Swap 使用策略（当内存使用到 70% 时开始使用 Swap）
sysctl vm.swappiness=30
echo 'vm.swappiness=30' >> /etc/sysctl.conf
```

---

## 六、系统优化配置

```bash
# /etc/sysctl.conf
# 网络优化
net.ipv4.tcp_max_syn_backlog = 4096
net.core.somaxconn = 512
net.core.netdev_max_backlog = 2048
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 内存 overcommit（允许内存超售）
vm.overcommit_memory = 1
vm.overcommit_ratio = 80

# Swap 使用策略
vm.swappiness = 30
vm.vfs_cache_pressure = 50

# 文件描述符
fs.file-max = 300000
```

---

## 七、完整成本清单

### 首年成本（新用户）

| 项目 | 年成本 | 说明 |
|------|--------|------|
| ECS (2核4G) | **¥299** | 新用户3年优惠 |
| 域名 (.com) | ¥69 | 首年 |
| SSL 证书 | ¥0 | Let's Encrypt 免费 |
| 弹性IP | ¥180 | 必需 |
| 对象存储 | ¥0 | UCloud 免费额度 |
| **合计** | **¥548** | **¥46/月** |

### 续费成本

| 项目 | 年成本 | 月均 |
|------|--------|------|
| ECS (2核4G) | ¥1,500 | ¥125 |
| 域名 | ¥69 | ¥6 |
| SSL | ¥0 | ¥0 |
| 弹性IP | ¥180 | ¥15 |
| 对象存储 | ¥0 | ¥0（小流量） |
| **合计** | **¥1,749** | **¥146/月** |

---

## 八、部署步骤

### 1. 系统初始化

```bash
# 上传项目
scp -r mall root@your-server:/opt/

# 登录服务器
ssh root@your-server

# 初始化
cd /opt/mall/document/sh
sudo ./init-server.sh

# 配置 Swap（重要！）
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### 2. 创建配置文件

```bash
# 创建配置目录
mkdir -p /opt/mall/config/{mysql,mongo,elasticsearch}

# 创建配置文件（见上文）
vi /opt/mall/config/mysql/my.cnf
vi /opt/mall/config/mongo/mongod.conf
vi /opt/mall/config/elasticsearch/elasticsearch.yml
```

### 3. 配置环境变量

```bash
# 复制模板
cp /opt/mall/config/.env.example /opt/mall/config/.env

# 编辑配置
vi /opt/mall/config/.env
```

**环境变量示例：**

```bash
# 数据库
DB_HOST=mysql
DB_ROOT_PASSWORD=StrongRootPassword123!
DB_USER=mall_app
DB_PASSWORD=StrongAppPassword123!

# Redis
REDIS_PASSWORD=StrongRedisPassword123!

# MongoDB
MONGO_USER=mall_mongo
MONGO_PASSWORD=StrongMongoPassword123!

# RabbitMQ
MQ_USER=mall_mq
MQ_PASSWORD=StrongMqPassword123!

# JWT
JWT_SECRET=your-64-character-random-secret-key-here-change-this-in-production

# UCloud 对象存储
US3_PUBLIC_KEY=your-public-key
US3_PRIVATE_KEY=your-private-key
US3_BUCKET=mall-prod

# 镜像仓库（可选）
REGISTRY=registry.cn-shanghai.aliyuncs.com/mall
VERSION=1.0.0
```

### 4. 启动服务

```bash
# 启动所有服务
docker-compose -f document/docker/docker-compose-full-optimized.yml up -d

# 查看状态
docker-compose -f document/docker/docker-compose-full-optimized.yml ps

# 查看日志
docker-compose -f document/docker/docker-compose-full-optimized.yml logs -f
```

### 5. 初始化数据

```bash
# 导入数据库
docker exec -i mall-mysql mysql -u root -p${DB_ROOT_PASSWORD} mall < document/sql/mall.sql
```

### 6. 配置 Nginx

```bash
# 复制配置
cp document/nginx/mall.conf /etc/nginx/conf.d/

# 修改对象存储路径（如果使用 UCloud）
vi /etc/nginx/conf.d/mall.conf

# 申请 SSL 证书
certbot --nginx -d yourdomain.com

# 重启 Nginx
nginx -s reload
```

---

## 九、监控和维护

### 内存监控

```bash
# 实时监控内存
watch -n 1 free -h

# 查看 Docker 容器内存使用
docker stats

# 查看进程内存
ps aux --sort=-%mem | head
```

### 性能调优建议

1. **如果内存不够**：
   - 降低 MySQL 的 innodb_buffer_pool_size
   - 降低 ES 的堆内存
   - 考虑关闭 MongoDB（浏览历史功能）

2. **如果性能不够**：
   - 升级到 2核8G（¥125/月）
   - 或者使用阿里云的 MySQL 托管

3. **定期清理**：
   - 清理 Redis 过期键
   - 清理 ES 旧索引
   - 清理日志文件

---

## 十、总结

### 方案特点

✅ **全功能**：包含 Elasticsearch 搜索
✅ **低成本**：首年 ¥46/月，续费 ¥146/月
✅ **可运行**：通过优化可以在 2核4G 上运行
⚠️ **需注意**：内存紧张，需要持续监控

### 升级路径

如果业务增长，建议升级到 **2核8G**：
- 更加稳定
- 不需要这么多优化
- 支持更大流量

### 文件清单

| 文件 | 路径 |
|------|------|
| Docker Compose | document/docker/docker-compose-full-optimized.yml |
| MySQL 配置 | /opt/mall/config/mysql/my.cnf |
| MongoDB 配置 | /opt/mall/config/mongo/mongod.conf |
| ES 配置 | /opt/mall/config/elasticsearch/elasticsearch.yml |
| 环境变量 | /opt/mall/config/.env |

---

*文档生成时间: 2026-01-14*
