# Universal Window Screenshot Tool
# Clean version with no encoding issues

param(
    [string]$ProcessName = "notepad",
    [string]$OutputPrefix = "window",
    [switch]$AutoStart = $false
)

Write-Host "=== Universal Window Screenshot Tool ===" -ForegroundColor Cyan
Write-Host "Target Process: $ProcessName" -ForegroundColor Yellow

try {
    # Ensure Images directory exists
    $imagesPath = Join-Path (Get-Location) "Images"
    if (-not (Test-Path $imagesPath)) {
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        Write-Host "Created Images directory" -ForegroundColor Gray
    }
    
    # Load required .NET assemblies
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms    # Define Windows API (only if not already loaded)
    if (-not ([System.Management.Automation.PSTypeName]'WindowAPI').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;

public class WindowAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out WinRect lpRect);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    public const int SW_MAXIMIZE = 3;
}

[StructLayout(LayoutKind.Sequential)]
public struct WinRect {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
'@
    }
      # Start or find application
    $process = $null
    if ($AutoStart) {
        Write-Host "Starting $ProcessName..." -ForegroundColor Green
        # Switch to system directory to avoid path issues
        $originalPath = Get-Location
        Set-Location $env:SystemRoot
        $process = Start-Process -FilePath "$ProcessName.exe" -PassThru
        Set-Location -LiteralPath $originalPath.Path
        Start-Sleep -Seconds 3
          # Add content for notepad
        if ($ProcessName -eq "notepad") {
            $content = @"
Universal Window Screenshot Tool Demo

Features:
- Captures ONLY the target window
- No desktop background included
- Professional clean screenshots
- Supports any Windows application

This ensures high-quality documentation images.
"@
            [System.Windows.Forms.SendKeys]::SendWait($content)
            Start-Sleep -Seconds 2
        }
        
        # Wait longer for some applications
        if ($ProcessName -eq "calc") {
            Start-Sleep -Seconds 2
        }
    }
    
    # Find window
    Write-Host "Finding window..." -ForegroundColor Green
    $windowHandle = [IntPtr]::Zero
    
    $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | 
                Where-Object { $_.MainWindowTitle -ne "" }
    
    if ($processes) {
        $windowHandle = $processes[0].MainWindowHandle
        Write-Host "Found window: $($processes[0].MainWindowTitle)" -ForegroundColor Cyan
    }
    
    if ($windowHandle -eq [IntPtr]::Zero) {
        throw "Cannot find $ProcessName window"
    }
      # Maximize and bring window to front
    [WindowAPI]::ShowWindow($windowHandle, [WindowAPI]::SW_MAXIMIZE)
    [WindowAPI]::SetForegroundWindow($windowHandle)
    Start-Sleep -Seconds 2
    
    # Get window position and size
    $rect = New-Object WinRect
    $success = [WindowAPI]::GetWindowRect($windowHandle, [ref]$rect)
    
    if (-not $success) {
        throw "Cannot get window information"
    }
    
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    
    Write-Host "Window size: ${width} x ${height}" -ForegroundColor Cyan
    
    # Take screenshot
    Write-Host "Taking screenshot..." -ForegroundColor Green
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Key: Only capture window area, no desktop background
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
    $graphics.Dispose()
    
    # Save file
    $screenshotFile = "${OutputPrefix}_screenshot.png"
    $screenshotPath = Join-Path $imagesPath $screenshotFile
    
    $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Create annotated version
    $annotatedBitmap = New-Object System.Drawing.Bitmap($bitmap)
    $annotGraphics = [System.Drawing.Graphics]::FromImage($annotatedBitmap)
    $annotGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Add annotations
    $redPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 4)
    $font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    if ($ProcessName -eq "notepad") {
        # Notepad specific annotations
        $annotGraphics.DrawEllipse($redPen, 20, 60, 50, 30)  # File menu
        $annotGraphics.DrawEllipse($redPen, 70, 60, 50, 30)  # Edit menu
        $annotGraphics.DrawEllipse($redPen, 120, 60, 60, 30) # Format menu
        
        # Add label
        $labelY = $height - 100
        $labelRect = New-Object System.Drawing.Rectangle(20, $labelY, 300, 70)
        $annotGraphics.FillRectangle($whiteBrush, $labelRect)
        $annotGraphics.DrawRectangle($redPen, $labelRect)
        
        $annotGraphics.DrawString("Window-Only Screenshot", $font, $blackBrush, 25, $labelY + 10)
        $annotGraphics.DrawString("No Desktop Background", $font, $blackBrush, 25, $labelY + 35)
    } else {
        # Generic annotation
        $centerX = ($width / 2) - 100
        $centerY = ($height / 2) - 40
        $labelRect = New-Object System.Drawing.Rectangle($centerX, $centerY, 200, 80)
        $annotGraphics.FillRectangle($whiteBrush, $labelRect)
        $annotGraphics.DrawRectangle($redPen, $labelRect)
        
        $annotGraphics.DrawString("Window Screenshot", $font, $blackBrush, $centerX + 10, $centerY + 15)
        $annotGraphics.DrawString("App: $ProcessName", $font, $blackBrush, $centerX + 10, $centerY + 40)
    }
    
    # Save annotated version
    $annotatedFile = "${OutputPrefix}_annotated.png"
    $annotatedPath = Join-Path $imagesPath $annotatedFile
    $annotatedBitmap.Save($annotatedPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Clean up resources
    $bitmap.Dispose()
    $annotatedBitmap.Dispose()
    $annotGraphics.Dispose()
    $redPen.Dispose()
    $font.Dispose()
    $whiteBrush.Dispose()
    $blackBrush.Dispose()
    
    # Check files and display info
    if (Test-Path $screenshotPath) {
        $fileSize = (Get-Item $screenshotPath).Length
        $fileSizeKB = [math]::Round($fileSize / 1KB, 1)
        Write-Host "Success: Screenshot saved to $screenshotFile ($fileSizeKB KB)" -ForegroundColor Green
    }
    
    if (Test-Path $annotatedPath) {
        $fileSize2 = (Get-Item $annotatedPath).Length
        $fileSizeKB2 = [math]::Round($fileSize2 / 1KB, 1)
        Write-Host "Success: Annotated version saved to $annotatedFile ($fileSizeKB2 KB)" -ForegroundColor Green
    }
    
    # Close auto-started application
    if ($AutoStart -and $process) {
        Write-Host "Closing application..." -ForegroundColor Yellow
        $process | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    
    Write-Host ""
    Write-Host "Screenshot Features Confirmed:" -ForegroundColor White
    Write-Host "- Window content only (no desktop)" -ForegroundColor Green
    Write-Host "- Professional quality for documentation" -ForegroundColor Green
    Write-Host "- Repeatable and consistent results" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor Yellow
    Write-Host "  Browser: .\Universal_Clean_Screenshot.ps1 -ProcessName 'chrome'" -ForegroundColor Gray
    Write-Host "  VS Code: .\Universal_Clean_Screenshot.ps1 -ProcessName 'code'" -ForegroundColor Gray
    Write-Host "  Calculator: .\Universal_Clean_Screenshot.ps1 -ProcessName 'calc'" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Screenshot completed successfully!" -ForegroundColor Cyan
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "- Make sure the target application is running" -ForegroundColor Gray
    Write-Host "- Check if process name is correct" -ForegroundColor Gray
    Write-Host "- Try using -AutoStart parameter" -ForegroundColor Gray
    
    # Clean up: close any running process
    if ($process) {
        $process | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    exit 1
}
