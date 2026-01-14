@echo off
REM =============================================================================
REM Mall 电商系统 - 停止服务脚本
REM 适用于: Windows
REM =============================================================================

echo =========================================
echo 停止 Mall 服务
echo =========================================
echo.

cd /d "%~dp0"

set /p confirm="是否保留数据卷? (Y/n): "
if /i "%confirm%"=="n" (
    echo 停止服务并删除数据...
    docker-compose down -v
) else (
    echo 停止服务（保留数据）...
    docker-compose down
)

echo.
echo 服务已停止
echo.
echo 重新启动请运行: start.bat
echo.
pause
