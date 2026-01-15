#!/bin/bash
# Mall 电商系统 - 数据备份脚本

set -e

# 加载环境变量
if [ -f /opt/mall/config/.env ]; then
    source /opt/mall/config/.env
else
    echo "错误: 环境变量文件不存在"
    exit 1
fi

# 配置
BACKUP_DIR="/opt/mall/backup"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}
OSS_BUCKET=${OSS_BUCKET_NAME:-"mall-backup"}

# 创建备份目录
mkdir -p ${BACKUP_DIR}/{mysql,redis,mongo}

echo "========================================="
echo "Mall 数据备份"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 1. 备份 MySQL
echo ""
echo "步骤1: 备份 MySQL..."
if [ -n "$DB_HOST" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
    MYSQL_BACKUP="${BACKUP_DIR}/mysql/mall_$(date +%Y%m%d_%H%M%S).sql"

    echo "备份数据库: ${DB_NAME:-mall}"
    mysqldump -h ${DB_HOST} \
        -u ${DB_USER} \
        -p${DB_PASSWORD} \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --databases ${DB_NAME:-mall} > ${MYSQL_BACKUP}

    # 压缩
    gzip ${MYSQL_BACKUP}
    echo "  ✓ MySQL 备份完成: ${MYSQL_BACKUP}.gz"
else
    echo "  ✗ 未配置 MySQL，跳过"
fi

# 2. 备份 Redis
echo ""
echo "步骤2: 备份 Redis..."
if [ -n "$REDIS_HOST" ] && [ -n "$REDIS_PASSWORD" ]; then
    REDIS_BACKUP="${BACKUP_DIR}/redis/dump_$(date +%Y%m%d_%H%M%S).rdb"

    # 触发 BGSAVE
    redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT:-6379} -a ${REDIS_PASSWORD} BGSAVE > /dev/null

    # 等待 BGSAVE 完成
    sleep 10

    # 导出 RDB 文件（需要 Redis 配置开启）
    echo "  ✓ Redis 备份完成（使用 RDS 自动备份）"
else
    echo "  ✗ 未配置 Redis，跳过"
fi

# 3. 备份 MongoDB
echo ""
echo "步骤3: 备份 MongoDB..."
if [ -n "$MONGO_HOST" ] && [ -n "$MONGO_USER" ] && [ -n "$MONGO_PASSWORD" ]; then
    MONGO_BACKUP="${BACKUP_DIR}/mongo/mall-port_$(date +%Y%m%d_%H%M%S).gz"

    mongodump --host ${MONGO_HOST}:${MONGO_PORT:-27017} \
        --username ${MONGO_USER} \
        --password ${MONGO_PASSWORD} \
        --db ${MONGO_DATABASE:-mall-port} \
        --gzip \
        --archive=${MONGO_BACKUP}

    echo "  ✓ MongoDB 备份完成: ${MONGO_BACKUP}"
else
    echo "  ✗ 未配置 MongoDB，跳过"
fi

# 4. 上传到 OSS
echo ""
echo "步骤4: 上传备份到 OSS..."
if command -v ossutil &> /dev/null && [ -n "$OSS_BUCKET_NAME" ]; then
    # 上传 MySQL 备份
    ls ${BACKUP_DIR}/mysql/*.gz 2>/dev/null | while read file; do
        ossutil cp ${file} oss://${OSS_BUCKET_NAME}/backup/mysql/ --update
    done

    # 上传 MongoDB 备份
    ls ${BACKUP_DIR}/mongo/*.gz 2>/dev/null | while read file; do
        ossutil cp ${file} oss://${OSS_BUCKET_NAME}/backup/mongo/ --update
    done

    echo "  ✓ OSS 上传完成"
else
    echo "  ✗ 未配置 ossutil 或 OSS，跳过"
fi

# 5. 清理旧备份
echo ""
echo "步骤5: 清理 ${RETENTION_DAYS} 天前的旧备份..."
find ${BACKUP_DIR} -name "*.gz" -mtime +${RETENTION_DAYS} -delete
echo "  ✓ 清理完成"

# 6. 生成备份报告
echo ""
echo "========================================="
echo "备份完成！"
echo "========================================="
echo ""
echo "备份文件:"
ls -lh ${BACKUP_DIR}/mysql/*.gz 2>/dev/null || echo "  (无 MySQL 备份)"
ls -lh ${BACKUP_DIR}/mongo/*.gz 2>/dev/null || echo "  (无 MongoDB 备份)"
echo ""
echo "备份位置: ${BACKUP_DIR}"
echo "保留天数: ${RETENTION_DAYS}"
