@echo off
REM VetRAI Production Deployment Script for Windows
REM Usage: deploy.bat [start|stop|restart|logs|status]

setlocal enabledelayedexpansion

set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=start

set COMPOSE_FILE=docker-compose.yml

if "%COMMAND%"=="start" (
    echo [VetRAI] Starting VetRAI production stack...
    docker compose -f %COMPOSE_FILE% up -d
    echo [VetRAI] Services started
    echo [VetRAI] Waiting for services to be healthy (30 seconds)...
    timeout /t 30 /nobreak
    docker compose -f %COMPOSE_FILE% ps
    echo [VetRAI] Access frontend at http://localhost
    echo [VetRAI] API documentation at http://localhost/docs
) else if "%COMMAND%"=="stop" (
    echo [VetRAI] Stopping VetRAI production stack...
    docker compose -f %COMPOSE_FILE% down
    echo [VetRAI] Services stopped
) else if "%COMMAND%"=="restart" (
    echo [VetRAI] Restarting VetRAI production stack...
    docker compose -f %COMPOSE_FILE% restart
    echo [VetRAI] Services restarted
) else if "%COMMAND%"=="logs" (
    echo [VetRAI] Showing logs ^(press Ctrl+C to exit^)...
    docker compose -f %COMPOSE_FILE% logs -f
) else if "%COMMAND%"=="status" (
    echo [VetRAI] Service Status:
    docker compose -f %COMPOSE_FILE% ps
) else if "%COMMAND%"=="update" (
    echo [VetRAI] Updating images from Docker Hub...
    docker compose -f %COMPOSE_FILE% pull
    echo [VetRAI] Restarting services with new images...
    docker compose -f %COMPOSE_FILE% up -d
    echo [VetRAI] Update complete
) else if "%COMMAND%"=="clean" (
    echo [WARNING] This will remove all containers and data
    set /p confirm="Are you sure? (yes/no): "
    if "!confirm!"=="yes" (
        docker compose -f %COMPOSE_FILE% down -v
        echo [VetRAI] All data removed
    ) else (
        echo [VetRAI] Cancelled
    )
) else (
    echo [ERROR] Unknown command: %COMMAND%
    echo.
    echo Usage: deploy.bat [command]
    echo.
    echo Commands:
    echo   start     - Start all services
    echo   stop      - Stop all services
    echo   restart   - Restart all services
    echo   logs      - Show live logs (Ctrl+C to exit)
    echo   status    - Show service status
    echo   update    - Pull latest images and restart
    echo   clean     - Remove all containers and data (WARNING)
    exit /b 1
)

endlocal
