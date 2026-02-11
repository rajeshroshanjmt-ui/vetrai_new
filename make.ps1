# VetRAI Windows Makefile (PowerShell)
# Provides common development commands for Windows users
# Usage: .\make.ps1 -Task init
#        .\make.ps1 -Task run-backend
#        .\make.ps1 -Task help

param(
    [string]$Task = "help",
    [int]$Port = 7680,
    [string]$Host = "0.0.0.0",
    [int]$Workers = 2,
    [switch]$SkipBuild = $false
)

$ErrorActionPreference = "Continue"

# Colors
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

# Helper functions
function Write-Header {
    param([string]$Title)
    Write-Host "`n════════════════════════════════════════════════════════════" -ForegroundColor $Cyan
    Write-Host "  $Title" -ForegroundColor $Cyan
    Write-Host "════════════════════════════════════════════════════════════`n" -ForegroundColor $Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor $Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor $Red
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor $Yellow
}

function Check-Command {
    param([string]$Command)
    try {
        $null = & $Command --version 2>&1
        Write-Success "Found $Command"
        return $true
    } catch {
        Write-Error "$Command not found"
        return $false
    }
}

function Install-Dependencies {
    Write-Header "Installing Dependencies"
    
    # Check tools
    Write-Host "Checking required tools..." -ForegroundColor $Yellow
    $allOk = $true
    $allOk = $allOk -and (Check-Command "python")
    $allOk = $allOk -and (Check-Command "node")
    $allOk = $allOk -and (Check-Command "npm")
    
    if (-not $allOk) {
        Write-Error "Please install missing tools"
        exit 1
    }
    
    # Create virtual environment
    Write-Host "`nSetting up Python environment..." -ForegroundColor $Yellow
    if (-not (Test-Path ".venv")) {
        python -m venv .venv
        Write-Success "Created virtual environment"
    }
    
    # Activate venv
    if ($IsWindows) {
        & .\.venv\Scripts\Activate.ps1
    } else {
        & .\.venv\bin\Activate.ps1
    }
    
    # Install uv
    Write-Host "Installing/upgrading uv..." -ForegroundColor $Yellow
    python -m pip install --upgrade uv --quiet
    Write-Success "uv ready"
    
    # Install dependencies
    Write-Host "Installing dependencies with uv..." -ForegroundColor $Yellow
    uv pip install --quiet fastapi uvicorn langflow-base langchain langchain-core python-dotenv pydantic sqlalchemy
    Write-Success "Dependencies installed"
}

function Build-Frontend {
    param([switch]$Skip = $false)
    
    if ($Skip) {
        Write-Warning "Skipping frontend build"
        return
    }
    
    Write-Header "Building Frontend"
    
    $FrontendDir = "src\frontend"
    if (-not (Test-Path $FrontendDir)) {
        Write-Error "Frontend directory not found: $FrontendDir"
        return
    }
    
    Push-Location $FrontendDir
    
    if (-not (Test-Path "node_modules")) {
        Write-Host "Installing npm dependencies..." -ForegroundColor $Yellow
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "npm install failed"
            Pop-Location
            exit 1
        }
    }
    
    Write-Host "Running build..." -ForegroundColor $Yellow
    npm run build
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Frontend build failed"
        Pop-Location
        exit 1
    }
    
    Write-Host "Copying built files..." -ForegroundColor $Yellow
    $DestDir = "..\backend\base\vetrai\frontend"
    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }
    Copy-Item "build\*" $DestDir -Recurse -Force
    Write-Success "Frontend built and copied"
    
    Pop-Location
}

function Run-Backend {
    Write-Header "Starting VetRAI Backend"
    
    Write-Host "Configuration:" -ForegroundColor $Cyan
    Write-Host "  Port: $Port"
    Write-Host "  Host: $Host"
    Write-Host "  Workers: $Workers"
    Write-Host "  API: http://$($Host):$Port/api"
    Write-Host "  Health: http://localhost:$Port/health_check" -ForegroundColor $Green
    
    Write-Host "`nStarting server...`n" -ForegroundColor $Yellow
    
    # Set environment
    $env:PYTHONDONTWRITEBYTECODE = "1"
    $env:PYTHONUNBUFFERED = "1"
    $env:LANGFLOW_AUTO_LOGIN = "true"
    
    python -m uvicorn --factory langflow.main:create_app `
        --host $Host `
        --port $Port `
        --workers $Workers `
        --reload `
        --log-level info
}

function Run-Frontend-Dev {
    Write-Header "Starting Frontend Dev Server"
    
    $FrontendDir = "src\frontend"
    
    if (-not (Test-Path "$FrontendDir\node_modules")) {
        Write-Host "Installing dependencies..." -ForegroundColor $Yellow
        Push-Location $FrontendDir
        npm install
        Pop-Location
    }
    
    Write-Host "Starting Vite dev server on http://localhost:5173`n" -ForegroundColor $Yellow
    
    Push-Location $FrontendDir
    npm run dev
    Pop-Location
}

function Run-Tests {
    Write-Header "Running Tests"
    
    Write-Host "Activating virtual environment..." -ForegroundColor $Yellow
    if ($IsWindows) {
        & .\.venv\Scripts\Activate.ps1
    } else {
        & .\.venv\bin\Activate.ps1
    }
    
    Write-Host "Running pytest..." -ForegroundColor $Yellow
    pytest --cov=src tests/
}

function Format-Code {
    Write-Header "Formatting Code"
    
    Write-Host "Activating virtual environment..." -ForegroundColor $Yellow
    if ($IsWindows) {
        & .\.venv\Scripts\Activate.ps1
    } else {
        & .\.venv\bin\Activate.ps1
    }
    
    Write-Host "Running ruff format..." -ForegroundColor $Yellow
    ruff format src/
    
    Write-Host "Running ruff check..." -ForegroundColor $Yellow
    ruff check src/ --fix
    
    Write-Success "Code formatted"
}

function Clean-All {
    Write-Header "Cleaning All"
    
    Write-Host "Removing build artifacts..." -ForegroundColor $Yellow
    
    Get-ChildItem -Path . -Include "__pycache__", "*.pyc", ".pytest_cache", ".ruff_cache" -Recurse -Force | 
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    if (Test-Path "src\frontend\build") {
        Remove-Item "src\frontend\build" -Recurse -Force
    }
    
    if (Test-Path "src\frontend\node_modules") {
        Remove-Item "src\frontend\node_modules" -Recurse -Force
    }
    
    if (Test-Path ".venv") {
        Remove-Item ".venv" -Recurse -Force
    }
    
    Write-Success "Cleanup complete"
}

function Show-Help {
    Write-Header "VetRAI Windows Development Commands"
    
    Write-Host "Basic Commands:`n" -ForegroundColor $Cyan
    Write-Host "  .\make.ps1 -Task help                 Show this help message"
    Write-Host "  .\make.ps1 -Task init                 Initialize project (install dependencies)"
    Write-Host "  .\make.ps1 -Task build                Build frontend"
    Write-Host "  .\make.ps1 -Task run-backend          Start backend on port 7680"
    Write-Host "  .\make.ps1 -Task run-frontend         Start frontend dev server"
    Write-Host "  .\make.ps1 -Task run-all              Start both (backend + frontend)"
    Write-Host "  .\make.ps1 -Task test                 Run tests"
    Write-Host "  .\make.ps1 -Task format               Format code with ruff"
    Write-Host "  .\make.ps1 -Task clean                Clean all artifacts"
    
    Write-Host "`nBackend Options:`n" -ForegroundColor $Cyan
    Write-Host "  -Port 7680                            Backend port (default: 7680)"
    Write-Host "  -Workers 2                            Number of workers (default: 2)"
    Write-Host "  -Host 0.0.0.0                         Bind address (default: 0.0.0.0)"
    
    Write-Host "`nExamples:`n" -ForegroundColor $Cyan
    Write-Host "  .\make.ps1 -Task init                                 # First time setup"
    Write-Host "  .\make.ps1 -Task run-backend -Port 8000              # Custom port"
    Write-Host "  .\make.ps1 -Task run-backend -Workers 4              # More workers"
    Write-Host "  .\make.ps1 -Task build -SkipBuild                    # Skip build step"
}

# Main dispatcher
Write-Host ""
switch ($Task.ToLower()) {
    "help" { Show-Help }
    "init" { Install-Dependencies }
    "build" { Build-Frontend -Skip:$SkipBuild }
    "run-backend" { Build-Frontend; Run-Backend }
    "run-frontend" { Run-Frontend-Dev }
    "run-all" { Build-Frontend; Run-Backend }
    "test" { Run-Tests }
    "tests" { Run-Tests }
    "format" { Format-Code }
    "clean" { Clean-All }
    "clean-all" { Clean-All }
    default {
        Write-Error "Unknown task: $Task"
        Write-Host "Run '.\make.ps1 -Task help' for available commands`n"
        exit 1
    }
}
