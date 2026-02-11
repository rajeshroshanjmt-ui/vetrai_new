@echo off
REM Windows batch file to run VetRAI with Docker Compose

setlocal enabledelayedexpansion

echo.
echo ==========================================
echo VetRAI - Full Application with Docker
echo ==========================================
echo.

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    exit /b 1
)

echo Docker is installed
echo.

REM Get command from arguments
set COMMAND=%1
if "!COMMAND!"=="" set COMMAND=up

if "!COMMAND!"=="up" (
    echo Building and starting services...
    docker-compose up --build
) else if "!COMMAND!"=="down" (
    echo Stopping services...
    docker-compose down
) else if "!COMMAND!"=="logs" (
    echo Showing logs...
    docker-compose logs -f
) else if "!COMMAND!"=="restart" (
    echo Restarting services...
    docker-compose restart
) else if "!COMMAND!"=="clean" (
    echo Removing all containers and volumes...
    docker-compose down -v
    echo Clean complete!
) else (
    echo Usage: run.bat {up^|down^|logs^|restart^|clean}
    echo.
    echo Commands:
    echo   up       - Build and start all services (default)
    echo   down     - Stop all services
    echo   logs     - View live logs
    echo   restart  - Restart services
    echo   clean    - Remove all containers and volumes
    pause
    exit /b 1
)

echo.
echo ==========================================
echo VetRAI Setup Complete!
echo ==========================================
echo.
echo Access VetRAI at: http://localhost:7860
echo Database: localhost:5432
echo.
pause
