#!/bin/bash
# =============================================================================
# Mall 电商系统 - Swap 配置脚本
# 用途: 在 2核4G 服务器上创建 2GB Swap 分区，缓解内存压力
# =============================================================================

set -e

SWAP_FILE="/swapfile"
SWAP_SIZE=2048  # MB

echo "========================================="
echo "Swap 配置脚本"
echo "========================================="

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    echo "错误: 请使用 root 用户运行此脚本"
    exit 1
fi

# 检查是否已存在 Swap
if [ -f "$SWAP_FILE" ]; then
    echo "警告: Swap 文件已存在"
    read -p "是否要删除并重新创建? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除现有 Swap..."
        swapoff $SWAP_FILE 2>/dev/null || true
        rm -f $SWAP_FILE
    else
        echo "保留现有 Swap 配置"
        exit 0
    fi
fi

# 检查可用磁盘空间
AVAILABLE_SPACE=$(df / | awk 'NR==2 {print $4}')
REQUIRED_SPACE=$((SWAP_SIZE * 1024))  # 转换为 KB

if [ "$AVAILABLE_SPACE" -lt "$REQUIRED_SPACE" ]; then
    echo "错误: 磁盘空间不足"
    echo "需要: $((SWAP_SIZE))MB"
    echo "可用: $((AVAILABLE_SPACE / 1024))MB"
    exit 1
fi

# 创建 Swap 文件
echo ""
echo "步骤1: 创建 ${SWAP_SIZE}MB Swap 文件..."
dd if=/dev/zero of=$SWAP_FILE bs=1M count=$SWAP_SIZE status=progress

# 设置权限
echo ""
echo "步骤2: 设置 Swap 文件权限..."
chmod 600 $SWAP_FILE

# 创建 Swap
echo ""
echo "步骤3: 创建 Swap..."
mkswap $SWAP_FILE

# 启用 Swap
echo ""
echo "步骤4: 启用 Swap..."
swapon $SWAP_FILE

# 验证 Swap
echo ""
echo "步骤5: 验证 Swap..."
swapon --show

# 设置开机自动挂载
echo ""
echo "步骤6: 配置开机自动挂载..."
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    echo "已添加到 /etc/fstab"
else
    echo "/etc/fstab 中已存在配置"
fi

# 优化 Swap 使用策略
echo ""
echo "步骤7: 优化 Swap 使用策略..."
echo "设置 vm.swappiness = 30"
sysctl vm.swappiness=30
echo "vm.swappiness=30" >> /etc/sysctl.conf

echo ""
echo "========================================="
echo "Swap 配置完成！"
echo "========================================="
echo ""
echo "当前 Swap 状态:"
free -h

echo ""
echo "Swap 文件: $SWAP_FILE"
echo "Swap 大小: ${SWAP_SIZE}MB"
echo "Swap 策略: vm.swappiness=30"
echo ""
echo "说明: swappiness=30 表示当内存使用到 70% 时开始使用 Swap"
echo ""
echo "验证命令:"
echo "  free -h              # 查看内存使用"
echo "  swapon --show        # 查看 Swap 详情"
echo "  cat /proc/swaps      # 查看 Swap 使用情况"
echo ""
