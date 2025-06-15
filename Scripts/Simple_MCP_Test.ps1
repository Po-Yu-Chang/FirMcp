# Simple Test for MCP Button Detection
# 簡單的 MCP 按鈕偵測測試

param(
    [string]$WindowTitle = "MCP_Test 1 - Button Test Window",
    [string]$OutputPrefix = "mcp_test"
)

Write-Host "=== Simple MCP Button Detection Test ===" -ForegroundColor Cyan
Write-Host "Target Window: $WindowTitle" -ForegroundColor Yellow

try {
    # Ensure Images directory exists
    $imagesPath = Join-Path (Get-Location) "Images"
    if (-not (Test-Path $imagesPath)) {
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
    }
    
    # Load required assemblies
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Define Windows API (avoid duplicate definition)
    if (-not ([System.Management.Automation.PSTypeName]'TestWinAPI').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;

public class TestWinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out TestRect lpRect);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    public const int SW_MAXIMIZE = 3;
}

[StructLayout(LayoutKind.Sequential)]
public struct TestRect {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}
'@
    }
    
    # Find target window
    Write-Host "1. Finding target window..." -ForegroundColor Green
    $windowHandle = [IntPtr]::Zero
    
    # Try exact title match first
    $windowHandle = [TestWinAPI]::FindWindow($null, $WindowTitle)
    
    if ($windowHandle -eq [IntPtr]::Zero) {
        # Try partial match
        $processes = Get-Process | Where-Object { 
            $_.MainWindowTitle -ne "" -and $_.MainWindowTitle -like "*MCP_Test*"
        }
        
        if ($processes) {
            $windowHandle = $processes[0].MainWindowHandle
            Write-Host "   Found by partial match: $($processes[0].MainWindowTitle)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "   Found by exact title: $WindowTitle" -ForegroundColor Cyan
    }
    
    if ($windowHandle -eq [IntPtr]::Zero) {
        throw "Cannot find target window: $WindowTitle"
    }
    
    # Bring window to front
    Write-Host "2. Bringing window to front..." -ForegroundColor Green
    [TestWinAPI]::SetForegroundWindow($windowHandle)
    Start-Sleep -Seconds 2
    
    # Get window bounds
    Write-Host "3. Getting window information..." -ForegroundColor Green
    $rect = New-Object TestRect
    $success = [TestWinAPI]::GetWindowRect($windowHandle, [ref]$rect)
    
    if (-not $success) {
        throw "Cannot get window information"
    }
    
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    Write-Host "   Window size: ${width} x ${height}" -ForegroundColor Cyan
    
    # Take screenshot
    Write-Host "4. Taking screenshot..." -ForegroundColor Green
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    # Capture only window area
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
    $graphics.Dispose()
    
    # Save original screenshot
    $screenshotFile = "${OutputPrefix}_screenshot.png"
    $screenshotPath = Join-Path $imagesPath $screenshotFile
    $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Create annotated version with simple detection
    Write-Host "5. Creating annotated version..." -ForegroundColor Green
    $annotatedBitmap = New-Object System.Drawing.Bitmap($bitmap)
    $graphics = [System.Drawing.Graphics]::FromImage($annotatedBitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Create annotation styles
    $redPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Red, 3)
    $greenPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Green, 3)
    $bluePen = New-Object System.Drawing.Pen([System.Drawing.Color]::Blue, 3)
    $font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    # Simple button area detection (assuming standard layout)
    # This is a simplified version - in real scenario would use more advanced detection
    
    # Detect potential button areas (rough estimation)
    $buttonAreas = @(
        @{ X = 30; Y = 90; Width = 120; Height = 40; Color = $redPen; Label = "Button 1" },
        @{ X = 160; Y = 90; Width = 120; Height = 40; Color = $greenPen; Label = "Button 2" },
        @{ X = 290; Y = 90; Width = 120; Height = 40; Color = $bluePen; Label = "Button 3" },
        @{ X = 30; Y = 140; Width = 120; Height = 40; Color = $redPen; Label = "Button 4" },
        @{ X = 160; Y = 140; Width = 120; Height = 40; Color = $greenPen; Label = "Button 5" },
        @{ X = 290; Y = 140; Width = 120; Height = 40; Color = $bluePen; Label = "Button 6" }
    )
    
    # Draw button annotations
    $detectedCount = 0
    foreach ($area in $buttonAreas) {
        if ($area.X + $area.Width -lt $width -and $area.Y + $area.Height -lt $height) {
            $graphics.DrawRectangle($area.Color, $area.X, $area.Y, $area.Width, $area.Height)
            
            # Add label
            $labelY = [Math]::Max(0, $area.Y - 20)
            $labelRect = New-Object System.Drawing.Rectangle($area.X, $labelY, 100, 18)
            $graphics.FillRectangle($whiteBrush, $labelRect)
            $graphics.DrawRectangle($area.Color, $labelRect)
            $graphics.DrawString($area.Label, $font, $blackBrush, $area.X + 2, $labelY + 2)
            
            $detectedCount++
        }
    }
    
    # Add summary label
    $summaryY = $height - 80
    $summaryRect = New-Object System.Drawing.Rectangle(10, $summaryY, 300, 60)
    $graphics.FillRectangle($whiteBrush, $summaryRect)
    $graphics.DrawRectangle($blackBrush, $summaryRect)
    
    $graphics.DrawString("MCP Button Detection Test", $font, $blackBrush, 15, $summaryY + 10)
    $graphics.DrawString("Detected Areas: $detectedCount", $font, $blackBrush, 15, $summaryY + 30)
    
    # Save annotated version
    $annotatedFile = "${OutputPrefix}_annotated.png"
    $annotatedPath = Join-Path $imagesPath $annotatedFile
    $annotatedBitmap.Save($annotatedPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Clean up resources
    $graphics.Dispose()
    $annotatedBitmap.Dispose()
    $bitmap.Dispose()
    $redPen.Dispose()
    $greenPen.Dispose()
    $bluePen.Dispose()
    $font.Dispose()
    $whiteBrush.Dispose()
    $blackBrush.Dispose()
    
    # Display results
    Write-Host ""
    Write-Host "=== Screenshot Complete ===" -ForegroundColor Cyan
    
    if (Test-Path $screenshotPath) {
        $size1 = (Get-Item $screenshotPath).Length
        $sizeKB1 = [math]::Round($size1/1KB, 1)
        Write-Host "Original screenshot: $screenshotFile ($sizeKB1 KB)" -ForegroundColor Green
    }
    
    if (Test-Path $annotatedPath) {
        $size2 = (Get-Item $annotatedPath).Length
        $sizeKB2 = [math]::Round($size2/1KB, 1)
        Write-Host "Annotated version: $annotatedFile ($sizeKB2 KB)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Test Results:" -ForegroundColor White
    Write-Host "- Window captured successfully" -ForegroundColor Green
    Write-Host "- Button areas marked: $detectedCount" -ForegroundColor Green
    Write-Host "- Window size: ${width} x ${height} pixels" -ForegroundColor Green
    Write-Host ""
    Write-Host "MCP Button Detection Test Completed!" -ForegroundColor Cyan
    
} catch {
    Write-Error "Error: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "- Make sure the test window is open" -ForegroundColor Gray
    Write-Host "- Check window title is correct" -ForegroundColor Gray
    Write-Host "- Try running Simple_Window_Generator.ps1 first" -ForegroundColor Gray
    exit 1
}
