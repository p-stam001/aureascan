# PowerShell script to diagnose and fix Flutter build file locking issues
# This script helps identify and resolve "file is being used by another process" errors

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Flutter Build Error Fix Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Function to find processes locking a file
function Find-FileLock {
    param([string]$FilePath)
    
    Write-Host "Checking for processes locking: $FilePath" -ForegroundColor Yellow
    
    try {
        # Try to open the file exclusively to see if it's locked
        $file = [System.IO.File]::Open($FilePath, 'Open', 'ReadWrite', 'None')
        $file.Close()
        Write-Host "  [OK] File is not locked" -ForegroundColor Green
        return $null
    } catch {
        Write-Host "  [ERROR] File appears to be locked" -ForegroundColor Red
        
        # Use handle.exe if available, otherwise use alternative method
        $handlePath = "C:\Sysinternals\handle.exe"
        if (Test-Path $handlePath) {
            Write-Host "  Using handle.exe to find locking process..." -ForegroundColor Yellow
            $result = & $handlePath -a -nobanner $FilePath 2>&1
            Write-Host $result
        } else {
            Write-Host "  Tip: Install Sysinternals Handle.exe for detailed process info" -ForegroundColor Yellow
            Write-Host "  Download: https://docs.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor Yellow
        }
    }
}

# Step 1: Check for running Flutter/Dart/Gradle processes
Write-Host "Step 1: Checking for running Flutter/Dart/Gradle processes..." -ForegroundColor Cyan
$flutterProcesses = Get-Process | Where-Object {
    $_.ProcessName -match 'flutter|dart|gradle|java' -or
    $_.Path -like '*flutter*' -or
    $_.Path -like '*dart*' -or
    $_.Path -like '*gradle*'
}

if ($flutterProcesses) {
    Write-Host "  Found running processes:" -ForegroundColor Yellow
    $flutterProcesses | Select-Object ProcessName, Id, Path | Format-Table -AutoSize
    Write-Host "  Consider stopping these processes if build is stuck" -ForegroundColor Yellow
} else {
    Write-Host "  [OK] No Flutter/Dart/Gradle processes found" -ForegroundColor Green
}
Write-Host ""

# Step 2: Check specific files mentioned in errors
Write-Host "Step 2: Checking files mentioned in build errors..." -ForegroundColor Cyan

$projectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$fontFile = Join-Path $projectRoot "assets\fonts\Inter-Regular.otf"
$envFile = Join-Path $projectRoot "assets\.env"

if (Test-Path $fontFile) {
    Find-FileLock -FilePath $fontFile
} else {
    Write-Host "  [WARNING] Font file not found: $fontFile" -ForegroundColor Yellow
}

if (Test-Path $envFile) {
    Find-FileLock -FilePath $envFile
} else {
    Write-Host "  [WARNING] .env file not found: $envFile" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Clean build directory
Write-Host "Step 3: Cleaning Flutter build directory..." -ForegroundColor Cyan
$buildDir = Join-Path $projectRoot "build"
if (Test-Path $buildDir) {
    Write-Host "  Removing build directory..." -ForegroundColor Yellow
    try {
        Remove-Item -Path $buildDir -Recurse -Force -ErrorAction Stop
        Write-Host "  [OK] Build directory cleaned successfully" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Could not remove build directory: $_" -ForegroundColor Red
        Write-Host "  This might indicate files are still locked" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] Build directory doesn't exist" -ForegroundColor Green
}
Write-Host ""

# Step 4: Clean Flutter cache
Write-Host "Step 4: Running Flutter clean..." -ForegroundColor Cyan
try {
    flutter clean
    Write-Host "  [OK] Flutter clean completed" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Flutter clean failed: $_" -ForegroundColor Red
}
Write-Host ""

# Step 5: Recommendations
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Recommendations:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Close any editors/IDEs that might have these files open:" -ForegroundColor Yellow
Write-Host "   - Close VS Code, Android Studio, or any editor with the project open" -ForegroundColor White
Write-Host "   - Make sure assets/.env and assets/fonts/Inter-Regular.otf are not open" -ForegroundColor White
Write-Host ""
Write-Host "2. Check antivirus software:" -ForegroundColor Yellow
Write-Host "   - Temporarily disable real-time scanning for the project folder" -ForegroundColor White
Write-Host "   - Add project folder to antivirus exclusions" -ForegroundColor White
Write-Host ""
Write-Host "3. Restart your computer if the issue persists" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. After fixing, run:" -ForegroundColor Yellow
Write-Host "   flutter pub get" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor White
Write-Host ""
Write-Host "5. If files are still locked, use Process Explorer or Handle.exe:" -ForegroundColor Yellow
Write-Host "   - Download from: https://docs.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor White
Write-Host "   - Run: handle.exe assets\fonts\Inter-Regular.otf" -ForegroundColor White
Write-Host ""

Write-Host "Script completed!" -ForegroundColor Green

