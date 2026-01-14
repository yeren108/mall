# Mall 本地开发环境 - Docker 一键部署

跨平台一键启动方案，支持 Windows / macOS / Linux

## 快速开始

### Windows

```cmd
# 双击运行
start.bat

# 或命令行运行
cd deployment\local
start.bat
```

### macOS / Linux

```bash
# 添加执行权限（首次）
chmod +x deployment/local/*.sh

# 启动服务
cd deployment/local
./start.sh
```

## 目录结构

```
deployment/local/
├── docker-compose.yml       # Docker Compose 配置
├── Dockerfile.mall-admin    # 后台管理镜像
├── Dockerfile.mall-portal   # 前台商城镜像
├── Dockerfile.mall-search   # 搜索服务镜像
├── application-docker.yml   # 应用配置模板
├── start.sh                 # 启动脚本 (macOS/Linux)
├── start.bat                # 启动脚本 (Windows)
├── stop.sh                  # 停止脚本 (macOS/Linux)
└── stop.bat                 # 停止脚本 (Windows)
```

## 环境要求

- Docker Desktop 20.10+
- Docker Compose 2.0+
- 至少 4GB 可用内存
- 至少 10GB 可用磁盘空间

### 安装 Docker

**Windows:**
https://www.docker.com/products/docker-desktop/

**macOS:**
https://www.docker.com/products/docker-desktop/

**Linux:**
```bash
curl -fsSL https://get.docker.com | bash
```

## 访问地址

| 服务 | 地址 | 说明 |
|------|------|------|
| 后台管理 API | http://localhost:8080 | Swagger UI: /swagger-ui/ |
| 前台商城 API | http://localhost:8085 | |
| 搜索服务 API | http://localhost:8081 | |
| Elasticsearch | http://localhost:9200 | |
| RabbitMQ 管理界面 | http://localhost:15672 | 用户名/密码: mall/mall |

## 数据库连接

| 数据库 | 地址 | 用户名 | 密码 |
|--------|------|--------|------|
| MySQL | localhost:3306 | root | root |
| Redis | localhost:6379 | - | admin |
| MongoDB | localhost:27017 | - | - |

## 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service]

# 重启服务
docker-compose restart [service]

# 停止服务
./stop.sh  # macOS/Linux
stop.bat   # Windows

# 完全清理（包括数据）
docker-compose down -v
```

## 首次启动注意事项

1. **首次启动需要构建镜像**，大约需要 5-10 分钟

2. **数据库初始化**：
   - 脚本会自动导入 `init.sql`
   - 或手动导入：`docker exec -i mall-mysql mysql -uroot -proot mall < ../../document/sql/mall.sql`

3. **Elasticsearch 启动较慢**，请耐心等待

## 内存分配

| 服务 | 内存 |
|------|------|
| mall-admin | 512MB |
| mall-portal | 768MB |
| mall-search | 512MB |
| MySQL | 1GB |
| Elasticsearch | 1GB |
| 其他 | 500MB |
| **总计** | **~4.3GB** |

## 故障排查

### 端口冲突

如果端口被占用，修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "新端口:容器端口"
```

### 内存不足

如果 Docker 内存不足：
1. 打开 Docker Desktop
2. 进入 Settings -> Resources
3. 增加内存分配（建议 8GB+）

### 容器无法启动

```bash
# 查看详细日志
docker-compose logs [service]

# 重启服务
docker-compose restart [service]
```

### 数据库连接失败

```bash
# 检查 MySQL 是否就绪
docker exec mall-mysql mysqladmin ping -h localhost -uroot -proot

# 查看 MySQL 日志
docker-compose logs mysql
```

## 开发调试

### 热重载

本地开发时，建议直接运行 Spring Boot 应用：

```bash
# 后台管理
cd mall-admin
mvn spring-boot:run

# 前台商城
cd mall-portal
mvn spring-boot:run
```

### 远程调试

在 `docker-compose.yml` 中添加调试端口：

```yaml
ports:
  - "8080:8080"
  - "5005:5005"  # 调试端口
environment:
  - JAVA_OPTS=-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005
```

## 生产部署

本地环境仅用于开发，生产环境请使用：
- `deployment/optimized-4g/` - 2核4G 生产环境
- `document/docker/` - 原始部署方案

## 更新日志

- 2026-01-14: 初始版本，支持一键启动
