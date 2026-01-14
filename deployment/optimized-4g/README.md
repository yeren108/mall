# Mall 2核4G 全功能优化部署

## 目录结构

```
deployment/optimized-4g/
├── docker-compose.yml              # Docker Compose 配置
├── .env.example                    # 环境变量模板
├── config/                         # 配置文件目录
│   ├── mysql/
│   │   └── my.cnf                  # MySQL 优化配置
│   ├── mongo/
│   │   └── mongod.conf             # MongoDB 优化配置
│   └── elasticsearch/
│       └── elasticsearch.yml       # ES 优化配置
└── scripts/                        # 脚本目录
    ├── setup-swap.sh               # Swap 配置脚本
    └── deploy.sh                   # 部署脚本
```

## 快速开始

### 1. 上传项目到服务器

```bash
scp -r deployment/optimized-4g root@your-server:/opt/mall-deploy
```

### 2. 登录服务器

```bash
ssh root@your-server
cd /opt/mall-deploy
```

### 3. 配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑配置（务必修改所有密码）
vi .env
```

### 4. 配置 Swap（推荐）

```bash
chmod +x scripts/setup-swap.sh
./scripts/setup-swap.sh
```

### 5. 部署应用

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

## 内存分配

| 服务 | 内存占用 |
|------|----------|
| mall-admin | 350MB |
| mall-portal | 500MB |
| mall-search | 200MB |
| MySQL | 700MB |
| Redis | 150MB |
| MongoDB | 300MB |
| RabbitMQ | 200MB |
| Elasticsearch | 800MB |
| 系统 + Nginx | 550MB |
| **总计** | **~3.75GB** |

## 常用命令

```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service]

# 重启服务
docker-compose restart [service]

# 停止所有服务
docker-compose down

# 查看内存使用
docker stats

# 查看系统内存
free -h
```

## 访问地址

| 服务 | 地址 |
|------|------|
| 后台管理 API | http://localhost:8080 |
| 前台商城 API | http://localhost:8085 |
| 搜索服务 API | http://localhost:8081 |
| Elasticsearch | http://localhost:9200 |
| RabbitMQ 管理界面 | http://localhost:15672 |

## 注意事项

1. **务必修改所有默认密码**
2. **JWT_SECRET 必须使用 64 位随机字符串**
3. **生产环境请配置 HTTPS**
4. **定期备份数据**

## 成本估算

| 项目 | 年成本 |
|------|--------|
| ECS (2核4G) | ¥299 (新用户3年) |
| 续费 | ¥1,500/年 |
| 域名 + SSL | ¥69/年 |
| 对象存储 | ¥0 (免费额度) |
| **首年合计** | **¥548** |
| **月均** | **¥46/月** |
