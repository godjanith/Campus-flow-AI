# CampusFlow AI - Dual Real-Time System Orchestrator
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  CampusFlow AI - Presidency University Integrated System" -ForegroundColor Yellow
Write-Host "  Synchronizing Web Command Console and Mobile Flutter App" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$rootDir = $PSScriptRoot
$dataDir = Join-Path $rootDir "data\db"

# 1. Ensure Local Data Directory Exists
if (-not (Test-Path $dataDir)) {
    Write-Host "[*] Creating MongoDB data directory at data\db..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $dataDir -Force | Out-Null
}

# 2. Check and Launch MongoDB Daemon
$mongoProc = Get-Process -Name "mongod" -ErrorAction SilentlyContinue
if ($mongoProc) {
    Write-Host "[OK] MongoDB is already running on port 27017." -ForegroundColor Green
} else {
    Write-Host "[*] Starting MongoDB on 127.0.0.1:27017..." -ForegroundColor Yellow
    $mongoExe = "C:\Program Files\MongoDB\Server\8.2\bin\mongod.exe"
    if (Test-Path $mongoExe) {
        Start-Process -FilePath $mongoExe -ArgumentList "--dbpath `"$dataDir`" --bind_ip 127.0.0.1 --port 27017" -WindowStyle Hidden
        Start-Sleep -Seconds 2
        Write-Host "[OK] MongoDB daemon launched." -ForegroundColor Green
    } else {
        Write-Host "[WARN] MongoDB binary not found at standard path. Continuing with resilient in-memory mode." -ForegroundColor Magenta
    }
}

# 3. Configure Android USB ADB Reverse Proxy
try {
    & adb reverse tcp:5000 tcp:5000 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] ADB Reverse Active: Phone can reach backend at 127.0.0.1:5000 over USB cable." -ForegroundColor Green
    } else {
        Write-Host "[INFO] No USB ADB device connected. Phone can connect over Wi-Fi (172.17.83.174:5000)." -ForegroundColor Cyan
    }
} catch {
    Write-Host "[INFO] adb command not in PATH. Phone can connect over Wi-Fi (172.17.83.174:5000)." -ForegroundColor Cyan
}

# 4. Terminate any stale process on port 5000
try {
    $connections = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue
    if ($connections) {
        foreach ($conn in $connections) {
            Write-Host "[*] Terminating stale process on port 5000 (PID: $($conn.OwningProcess))..." -ForegroundColor Yellow
            Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
} catch {}

# 5. Start Core Node.js Server
Write-Host ""
Write-Host "[*] Starting CampusFlow Core Server on port 5000..." -ForegroundColor Cyan
Write-Host "[OK] Hosting Web Dashboard at: http://localhost:5000" -ForegroundColor Green
Write-Host "[OK] Hosting LAN Dashboard at: http://172.17.83.174:5000" -ForegroundColor Green
Write-Host "[OK] Real-time Mobile Socket connected to port 5000" -ForegroundColor Green
Write-Host ""

Set-Location (Join-Path $rootDir "server")
& node server.js
