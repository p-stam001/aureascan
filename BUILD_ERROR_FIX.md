# Flutter Build Error Fix Guide

## Problem Description

You're encountering these errors during Flutter build:

1. **Error 1**: Cannot copy `Inter-Regular.otf` - file is being used by another process
2. **Error 2**: Cannot copy `.env` - file is being used by another process

```
PathAccessException: Cannot copy file to '...', path = '...' 
(OS Error: The process cannot access the file because it is being used by another process., errno = 32)
```

## Root Causes

This is a **Windows file locking issue**. Common causes:

1. **Files open in editor/IDE**: VS Code, Android Studio, or other editors have the files open
2. **Antivirus software**: Real-time scanning is locking files during build
3. **Previous build process**: Stuck Flutter/Gradle processes still holding file handles
4. **Windows file system**: Windows sometimes doesn't release file locks immediately

## Solutions (Try in Order)

### Solution 1: Close All Editors and Clean Build

1. **Close all editors/IDEs** that have the project open:
   - Close VS Code
   - Close Android Studio
   - Close any other editors with the project open

2. **Make sure these files are NOT open**:
   - `assets/fonts/Inter-Regular.otf`
   - `assets/.env`

3. **Run cleanup commands**:
   ```powershell
   flutter clean
   flutter pub get
   ```

4. **Try building again**:
   ```powershell
   flutter run
   ```

### Solution 2: Check for Stuck Processes

1. **Check for running Flutter/Dart/Gradle processes**:
   ```powershell
   Get-Process | Where-Object {$_.ProcessName -match 'flutter|dart|gradle|java'}
   ```

2. **Kill stuck processes** (if found):
   ```powershell
   Stop-Process -Name "flutter" -Force -ErrorAction SilentlyContinue
   Stop-Process -Name "dart" -Force -ErrorAction SilentlyContinue
   Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
   ```

### Solution 3: Antivirus Exclusions

1. **Temporarily disable real-time scanning** for the project folder
2. **Add project folder to antivirus exclusions**:
   - Add `D:\Project\aureascan` to your antivirus exclusions
   - This prevents antivirus from locking files during build

### Solution 4: Use Diagnostic Script

Run the provided PowerShell script:
```powershell
powershell -ExecutionPolicy Bypass -File fix_build_errors.ps1
```

This script will:
- Check for running Flutter processes
- Test if files are locked
- Clean the build directory
- Run `flutter clean`
- Provide recommendations

### Solution 5: Manual File Check

If you have **Sysinternals Handle.exe** installed:

```powershell
# Download from: https://docs.microsoft.com/en-us/sysinternals/downloads/handle
handle.exe assets\fonts\Inter-Regular.otf
handle.exe assets\.env
```

This will show which process is locking each file.

### Solution 6: Restart Computer

If all else fails, **restart your computer** to release all file locks.

## Prevention Tips

1. **Close files before building**: Always close files in editors before running builds
2. **Add to antivirus exclusions**: Add your project folder to antivirus exclusions permanently
3. **Use `flutter clean` regularly**: Clean build artifacts when switching branches or after errors
4. **Close IDEs during builds**: Some IDEs can interfere with file operations

## Quick Fix Commands

Run these commands in sequence:

```powershell
# 1. Clean Flutter
flutter clean

# 2. Remove build directory manually (if flutter clean fails)
Remove-Item -Path "build" -Recurse -Force -ErrorAction SilentlyContinue

# 3. Get dependencies
flutter pub get

# 4. Try building again
flutter run
```

## Files Affected

- `assets/fonts/Inter-Regular.otf` - Font file used in the app
- `assets/.env` - Environment variables file

Both are defined in `pubspec.yaml`:
- Fonts: `flutter > fonts > family: Inter`
- Assets: `flutter > assets > - assets/.env`

## Additional Notes

- The error occurs during the `compileFlutterBuildDebug` task
- Flutter tries to copy these files to the build directory
- Windows prevents copying if files are locked by another process
- This is a Windows-specific issue (errno = 32 = ERROR_SHARING_VIOLATION)

## Still Having Issues?

If the problem persists:

1. Check Windows Event Viewer for file system errors
2. Run `chkdsk` on your drive to check for file system issues
3. Consider moving the project to a different drive
4. Check if any backup software is locking files
5. Disable Windows Defender real-time protection temporarily






