@echo off
REM =============================================================================
REM Mall 电商系统 - 本地开发环境启动脚本
REM 适用于: Windows
REM =============================================================================

setlocal enabledelayedexpansion

echo =========================================
echo Mall 本地开发环境启动
echo 操作系统: Windows
echo =========================================
echo.

REM 检查 Docker
echo [1/6] 检查 Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker 未安装
    echo 请先安装 Docker Desktop: https://www.docker.com/products/docker-desktop/
    pause
    exit /b 1
)
echo Docker 已安装
docker --version

REM 切换到脚本目录
cd /d "%~dp0"

REM 停止旧容器
echo.
echo [2/6] 停止旧容器...
docker-compose down 2>nul

REM 构建镜像
echo.
echo [3/6] 构建应用镜像...
echo 首次启动可能需要较长时间...
docker-compose build

REM 启动服务
echo.
echo [4/6] 启动服务...
docker-compose up -d

REM 等待服务启动
echo.
echo [5/6] 等待服务启动...
timeout /t 10 /nobreak >nul

REM 显示状态
echo.
echo [6/6] 服务状态:
docker-compose ps

REM 等待 MySQL 就绪
echo.
echo 等待数据库初始化...
set /a count=0
:wait_loop
if !count! geq 30 (
    echo 超时，请检查 MySQL 日志
    goto continue
)
docker exec mall-mysql mysqladmin ping -h localhost -uroot -proot >nul 2>&1
if errorlevel 1 (
    echo|set /p="."
    timeout /t 2 /nobreak >nul
    set /a count+=1
    goto wait_loop
)
echo.
echo MySQL 已就绪

:continue

REM 初始化数据库
echo.
echo 初始化数据库...
if exist init.sql (
    docker exec mall-mysql mysql -uroot -proot -e "USE mall; SHOW TABLES;" >nul 2>&1
    if errorlevel 1 (
        echo 导入数据库...
        type init.sql | docker exec -i mall-mysql mysql -uroot -proot mall
        echo 数据库初始化完成
    ) else (
        echo 数据库已初始化，跳过
    )
) else (
    echo [WARN] 数据库脚本不存在: init.sql
    echo 请手动导入数据库: ..\..\document\sql\mall.sql
)

echo.
echo =========================================
echo 启动完成！
echo =========================================
echo.
echo 访问地址:
echo   后台管理 API:       http://localhost:8080
echo   前台商城 API:        http://localhost:8085
echo   搜索服务 API:        http://localhost:8081
echo   Elasticsearch:      http://localhost:9200
echo   RabbitMQ 管理界面:   http://localhost:15672 (mall/mall)
echo.
echo 数据库连接:
echo   MySQL:   localhost:3306 (root/root)
echo   Redis:   localhost:6379 (密码: admin)
echo   MongoDB: localhost:27017
echo.
echo 查看日志:
echo   docker-compose logs -f [service]
echo.
echo 停止服务:
echo   docker-compose down
echo.
pause
