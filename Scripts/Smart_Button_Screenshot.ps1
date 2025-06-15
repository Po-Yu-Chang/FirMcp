# Advanced Window Screenshot with Button Detection
# 進階視窗截圖工具 - 支援智能按鈕識別和標註

param(
    [string]$ProcessName = "",
    [string]$WindowTitle = "",
    [string]$OutputPrefix = "smart_screenshot",
    [switch]$AutoDetectButtons = $true,
    [switch]$AutoStart = $false,
    [switch]$Maximize = $false,
    [int]$WaitSeconds = 3
)

Write-Host "=== 智能視窗截圖工具 ===" -ForegroundColor Cyan
Write-Host "支援自動按鈕識別和標註功能" -ForegroundColor Yellow
if ($ProcessName) { Write-Host "目標進程: $ProcessName" -ForegroundColor White }
if ($WindowTitle) { Write-Host "視窗標題: $WindowTitle" -ForegroundColor White }
Write-Host ""

try {
    # 確保 Images 目錄存在
    $imagesPath = Join-Path (Get-Location) "Images"
    if (-not (Test-Path $imagesPath)) {
        New-Item -ItemType Directory -Path $imagesPath -Force | Out-Null
        Write-Host "建立 Images 目錄" -ForegroundColor Gray
    }
    
    # 載入必要的 .NET 組件
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName UIAutomationClient
    Add-Type -AssemblyName UIAutomationTypes
    
    # 定義 Windows API（避免重複定義）
    if (-not ([System.Management.Automation.PSTypeName]'SmartWinAPI').Type) {
        Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class SmartWinAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out WinRect lpRect);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetClassName(IntPtr hWnd, System.Text.StringBuilder lpClassName, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetParent(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool EnumChildWindows(IntPtr hWndParent, EnumChildProc lpEnumFunc, IntPtr lParam);
    
    public delegate bool EnumChildProc(IntPtr hWnd, IntPtr lParam);
    
    public const int SW_MAXIMIZE = 3;
    public const uint GW_CHILD = 5;
    public const uint GW_HWNDNEXT = 2;
}

[StructLayout(LayoutKind.Sequential)]
public struct WinRect {
    public int Left;
    public int Top;
    public int Right;
    public int Bottom;
}

public class ButtonInfo {
    public IntPtr Handle { get; set; }
    public string Text { get; set; }
    public string ClassName { get; set; }
    public WinRect Bounds { get; set; }
    public int X { get; set; }
    public int Y { get; set; }
    public int Width { get; set; }
    public int Height { get; set; }
}
'@
    }
    
    # 尋找目標視窗
    Write-Host "1. 尋找目標視窗..." -ForegroundColor Green
    $windowHandle = [IntPtr]::Zero
    
    # 方法1：通過視窗標題尋找
    if ($WindowTitle) {
        $windowHandle = [SmartWinAPI]::FindWindow($null, $WindowTitle)
        if ($windowHandle -ne [IntPtr]::Zero) {
            Write-Host "   ✅ 通過視窗標題找到: $WindowTitle" -ForegroundColor Cyan
        }
    }
    
    # 方法2：通過進程名稱尋找
    if ($windowHandle -eq [IntPtr]::Zero -and $ProcessName) {
        $processes = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | 
                    Where-Object { $_.MainWindowTitle -ne "" }
        
        if ($processes) {
            $windowHandle = $processes[0].MainWindowHandle
            Write-Host "   ✅ 通過進程名稱找到: $($processes[0].MainWindowTitle)" -ForegroundColor Cyan
        }
    }
    
    # 如果都沒有指定，列出所有可見視窗供選擇
    if ($windowHandle -eq [IntPtr]::Zero -and -not $ProcessName -and -not $WindowTitle) {
        Write-Host "   🔍 尋找所有可見視窗..." -ForegroundColor Cyan
        $visibleWindows = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | 
                         Select-Object ProcessName, MainWindowTitle, MainWindowHandle |
                         Where-Object { $_.MainWindowTitle -match "TestWindow|Button|Form|視窗" }
        
        if ($visibleWindows) {
            Write-Host "   找到可能的測試視窗:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $visibleWindows.Count; $i++) {
                Write-Host "   [$i] $($visibleWindows[$i].MainWindowTitle)" -ForegroundColor White
            }
            
            # 選擇第一個測試視窗
            $windowHandle = $visibleWindows[0].MainWindowHandle
            Write-Host "   ✅ 自動選擇: $($visibleWindows[0].MainWindowTitle)" -ForegroundColor Cyan
        }
    }
    
    if ($windowHandle -eq [IntPtr]::Zero) {
        throw "無法找到目標視窗"
    }
    
    # 設定視窗狀態
    Write-Host "2. 設定視窗狀態..." -ForegroundColor Green
    if ($Maximize) {
        [SmartWinAPI]::ShowWindow($windowHandle, [SmartWinAPI]::SW_MAXIMIZE)
        Write-Host "   視窗已最大化" -ForegroundColor Cyan
    }
    [SmartWinAPI]::SetForegroundWindow($windowHandle)
    Write-Host "   視窗已帶到前景" -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    
    # 獲取視窗資訊
    Write-Host "3. 分析視窗結構..." -ForegroundColor Green
    $rect = New-Object WinRect
    $success = [SmartWinAPI]::GetWindowRect($windowHandle, [ref]$rect)
    
    if (-not $success) {
        throw "無法獲取視窗資訊"
    }
    
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
    Write-Host "   視窗大小: ${width} x ${height}" -ForegroundColor Cyan
    
    # 智能按鈕偵測
    $detectedButtons = @()
    if ($AutoDetectButtons) {
        Write-Host "4. 智能按鈕偵測..." -ForegroundColor Green
        
        # 使用 EnumChildWindows 來尋找子控件
        $buttonList = New-Object System.Collections.Generic.List[ButtonInfo]
        
        $enumCallback = {
            param($childHandle, $lParam)
            
            try {
                $className = New-Object System.Text.StringBuilder(256)
                [SmartWinAPI]::GetClassName($childHandle, $className, 256) | Out-Null
                
                $windowText = New-Object System.Text.StringBuilder(256)
                [SmartWinAPI]::GetWindowText($childHandle, $windowText, 256) | Out-Null
                
                # 檢查是否為按鈕類型的控件
                $classStr = $className.ToString()
                $textStr = $windowText.ToString()
                
                if ($classStr -match "Button|BUTTON" -or 
                    ($textStr -ne "" -and $textStr.Length -lt 50)) {
                    
                    $childRect = New-Object WinRect
                    if ([SmartWinAPI]::GetWindowRect($childHandle, [ref]$childRect)) {
                        $buttonInfo = New-Object ButtonInfo
                        $buttonInfo.Handle = $childHandle
                        $buttonInfo.Text = $textStr
                        $buttonInfo.ClassName = $classStr
                        $buttonInfo.Bounds = $childRect
                        $buttonInfo.X = $childRect.Left - $rect.Left
                        $buttonInfo.Y = $childRect.Top - $rect.Top
                        $buttonInfo.Width = $childRect.Right - $childRect.Left
                        $buttonInfo.Height = $childRect.Bottom - $childRect.Top
                        
                        $buttonList.Add($buttonInfo)
                    }
                }
            } catch {
                # 忽略錯誤，繼續處理其他控件
            }
            
            return $true
        }
        
        # 呼叫 EnumChildWindows
        $delegateType = [System.Func[IntPtr, IntPtr, bool]]
        $callback = $delegateType::new($enumCallback)
        [SmartWinAPI]::EnumChildWindows($windowHandle, $callback, [IntPtr]::Zero)
        
        $detectedButtons = $buttonList.ToArray()
        
        Write-Host "   ✅ 偵測到 $($detectedButtons.Count) 個可能的按鈕控件" -ForegroundColor Cyan
        foreach ($btn in $detectedButtons) {
            if ($btn.Text -ne "") {
                Write-Host "     - 按鈕: '$($btn.Text)' 位置: ($($btn.X), $($btn.Y)) 大小: $($btn.Width)x$($btn.Height)" -ForegroundColor Gray
            }
        }
    }
    
    # 執行截圖
    Write-Host "5. 執行視窗截圖..." -ForegroundColor Green
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    
    $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
    $graphics.Dispose()
    
    # 儲存原始截圖
    $screenshotFile = "${OutputPrefix}_screenshot.png"
    $screenshotPath = Join-Path $imagesPath $screenshotFile
    $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # 建立智能標註版本
    Write-Host "6. 建立智能標註版本..." -ForegroundColor Green
    $annotatedBitmap = New-Object System.Drawing.Bitmap($bitmap)
    $graphics = [System.Drawing.Graphics]::FromImage($annotatedBitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
    
    # 建立標註樣式
    $colors = @(
        [System.Drawing.Color]::Red,
        [System.Drawing.Color]::Green,
        [System.Drawing.Color]::Blue,
        [System.Drawing.Color]::Orange,
        [System.Drawing.Color]::Purple,
        [System.Drawing.Color]::Brown,
        [System.Drawing.Color]::Pink,
        [System.Drawing.Color]::Cyan
    )
    
    $font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    
    # 標註偵測到的按鈕
    $colorIndex = 0
    foreach ($button in $detectedButtons) {
        if ($button.Width -gt 10 -and $button.Height -gt 10) {
            $color = $colors[$colorIndex % $colors.Count]
            $pen = New-Object System.Drawing.Pen($color, 3)
            $brush = New-Object System.Drawing.SolidBrush($color)
            
            # 繪製按鈕邊框
            $graphics.DrawRectangle($pen, $button.X, $button.Y, $button.Width, $button.Height)
            
            # 如果有文字，添加標籤
            if ($button.Text -ne "" -and $button.Text.Length -lt 20) {
                $labelX = $button.X
                $labelY = [Math]::Max(0, $button.Y - 25)
                $labelRect = New-Object System.Drawing.Rectangle($labelX, $labelY, ($button.Text.Length * 8), 20)
                
                $graphics.FillRectangle($whiteBrush, $labelRect)
                $graphics.DrawRectangle($pen, $labelRect)
                $graphics.DrawString($button.Text, $font, $brush, $labelX + 2, $labelY + 2)
            }
            
            $pen.Dispose()
            $brush.Dispose()
            $colorIndex++
        }
    }
    
    # 添加標題標籤
    $titleY = $height - 100
    $titleRect = New-Object System.Drawing.Rectangle(10, $titleY, 400, 80)
    $graphics.FillRectangle($whiteBrush, $titleRect)
    $graphics.DrawRectangle($blackBrush, $titleRect)
    
    $graphics.DrawString("智能按鈕偵測結果", $font, $blackBrush, 15, $titleY + 10)
    $graphics.DrawString("偵測到 $($detectedButtons.Count) 個控件", $font, $blackBrush, 15, $titleY + 30)
    $graphics.DrawString("MCP 截圖工具自動標註", $font, $blackBrush, 15, $titleY + 50)
    
    # 儲存標註版本
    $annotatedFile = "${OutputPrefix}_annotated.png"
    $annotatedPath = Join-Path $imagesPath $annotatedFile
    $annotatedBitmap.Save($annotatedPath, [System.Drawing.Imaging.ImageFormat]::Png)
    
    # 清理資源
    $graphics.Dispose()
    $annotatedBitmap.Dispose()
    $bitmap.Dispose()
    $font.Dispose()
    $whiteBrush.Dispose()
    $blackBrush.Dispose()
    
    # 顯示結果
    Write-Host ""
    Write-Host "=== 智能截圖完成 ===" -ForegroundColor Cyan
    
    if (Test-Path $screenshotPath) {
        $size1 = (Get-Item $screenshotPath).Length
        $sizeKB1 = [math]::Round($size1/1KB, 1)
        Write-Host "✅ 原始截圖: $screenshotFile ($sizeKB1 KB)" -ForegroundColor Green
    }
    
    if (Test-Path $annotatedPath) {
        $size2 = (Get-Item $annotatedPath).Length
        $sizeKB2 = [math]::Round($size2/1KB, 1)
        Write-Host "✅ 智能標註版本: $annotatedFile ($sizeKB2 KB)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📊 智能分析結果:" -ForegroundColor White
    Write-Host "• 偵測到的控件數量: $($detectedButtons.Count)" -ForegroundColor Green
    Write-Host "• 有效按鈕數量: $(($detectedButtons | Where-Object { $_.Text -ne '' }).Count)" -ForegroundColor Green
    Write-Host "• 視窗大小: ${width} x ${height} 像素" -ForegroundColor Green
    Write-Host "• 自動標註: 已完成" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "🎯 MCP 整合測試成功！" -ForegroundColor Cyan
    
} catch {
    Write-Error "❌ 錯誤: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "🔧 建議檢查項目:" -ForegroundColor Yellow
    Write-Host "• 確認目標視窗正在顯示" -ForegroundColor Gray
    Write-Host "• 檢查視窗標題或進程名稱" -ForegroundColor Gray
    Write-Host "• 嘗試先執行隨機視窗產生器" -ForegroundColor Gray
    exit 1
}
