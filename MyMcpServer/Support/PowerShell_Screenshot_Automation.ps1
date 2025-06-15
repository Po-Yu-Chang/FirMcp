# PowerShell 截螢幕自動化範本系統
# 建立日期: 2025年6月14日
# 版本: 1.0
# 描述: 提供全方位的螢幕截圖自動化解決方案

# 載入必要的 .NET 類別
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore

# 全域變數設定
$script:ScreenshotPath = "$env:USERPROFILE\Desktop\Screenshots"
$script:LogPath = "$env:USERPROFILE\Desktop\Screenshot_Logs"
$script:ConfigPath = "$env:USERPROFILE\Desktop\Screenshot_Config.json"

# 確保目錄存在
if (!(Test-Path $script:ScreenshotPath)) { New-Item -ItemType Directory -Path $script:ScreenshotPath -Force }
if (!(Test-Path $script:LogPath)) { New-Item -ItemType Directory -Path $script:LogPath -Force }

# 截圖配置類別
class ScreenshotConfig {
    [string]$DefaultPath
    [string]$ImageFormat
    [int]$Quality
    [bool]$IncludeTimestamp
    [bool]$AutoSave
    [string]$NamingPattern
    
    ScreenshotConfig() {
        $this.DefaultPath = $script:ScreenshotPath
        $this.ImageFormat = "PNG"
        $this.Quality = 100
        $this.IncludeTimestamp = $true
        $this.AutoSave = $true
        $this.NamingPattern = "Screenshot_{0:yyyyMMdd_HHmmss}"
    }
}

# 截圖核心類別
class ScreenshotCore {
    [ScreenshotConfig]$Config
    
    ScreenshotCore([ScreenshotConfig]$config) {
        $this.Config = $config
    }
    
    # 全螢幕截圖
    [System.Drawing.Bitmap] CaptureFullScreen() {
        $bounds = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        try {
            $graphics.CopyFromScreen($bounds.X, $bounds.Y, 0, 0, $bounds.Size)
            return $bitmap
        }
        finally {
            $graphics.Dispose()
        }
    }
    
    # 指定視窗截圖
    [System.Drawing.Bitmap] CaptureWindow([string]$windowTitle) {
        $process = Get-Process | Where-Object { $_.MainWindowTitle -like "*$windowTitle*" } | Select-Object -First 1
        if (!$process) {
            throw "找不到視窗: $windowTitle"
        }
        
        $hwnd = $process.MainWindowHandle
        if ($hwnd -eq [System.IntPtr]::Zero) {
            throw "無法取得視窗控制代碼"
        }
        
        # 使用 Windows API 取得視窗區域
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            public class Win32 {
                [DllImport("user32.dll")]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
                [StructLayout(LayoutKind.Sequential)]
                public struct RECT {
                    public int Left, Top, Right, Bottom;
                }
            }
"@
        
        $rect = New-Object Win32+RECT
        [Win32]::GetWindowRect($hwnd, [ref]$rect)
        
        $width = $rect.Right - $rect.Left
        $height = $rect.Bottom - $rect.Top
        
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        try {
            $graphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, [System.Drawing.Size]::new($width, $height))
            return $bitmap
        }
        finally {
            $graphics.Dispose()
        }
    }
    
    # 區域截圖
    [System.Drawing.Bitmap] CaptureRegion([int]$x, [int]$y, [int]$width, [int]$height) {
        $bitmap = New-Object System.Drawing.Bitmap $width, $height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        
        try {
            $graphics.CopyFromScreen($x, $y, 0, 0, [System.Drawing.Size]::new($width, $height))
            return $bitmap
        }
        finally {
            $graphics.Dispose()
        }
    }
    
    # 儲存截圖
    [string] SaveScreenshot([System.Drawing.Bitmap]$bitmap, [string]$filename = "") {
        if ([string]::IsNullOrEmpty($filename)) {
            $timestamp = Get-Date
            $filename = $this.Config.NamingPattern -f $timestamp
        }
        
        $fullPath = Join-Path $this.Config.DefaultPath "$filename.$($this.Config.ImageFormat.ToLower())"
        
        switch ($this.Config.ImageFormat.ToUpper()) {
            "PNG" { $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png) }
            "JPEG" { $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Jpeg) }
            "BMP" { $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Bmp) }
            "GIF" { $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Gif) }
            default { $bitmap.Save($fullPath, [System.Drawing.Imaging.ImageFormat]::Png) }
        }
        
        return $fullPath
    }
}

# 自動化管理員類別
class ScreenshotAutomationManager {
    [ScreenshotCore]$Core
    [System.Collections.ArrayList]$ScheduledTasks
    [bool]$IsMonitoring
    
    ScreenshotAutomationManager([ScreenshotCore]$core) {
        $this.Core = $core
        $this.ScheduledTasks = New-Object System.Collections.ArrayList
        $this.IsMonitoring = $false
    }
    
    # 定時截圖
    [void] StartScheduledScreenshots([int]$intervalSeconds, [int]$maxCount = 0) {
        $count = 0
        $this.IsMonitoring = $true
        
        Write-Host "開始定時截圖，間隔: $intervalSeconds 秒" -ForegroundColor Green
        
        while ($this.IsMonitoring -and ($maxCount -eq 0 -or $count -lt $maxCount)) {
            try {
                $bitmap = $this.Core.CaptureFullScreen()
                $filename = "Scheduled_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                $savedPath = $this.Core.SaveScreenshot($bitmap, $filename)
                $bitmap.Dispose()
                
                $count++
                Write-Host "截圖 $count 已儲存: $savedPath" -ForegroundColor Cyan
                
                if ($maxCount -gt 0 -and $count -ge $maxCount) {
                    break
                }
                
                Start-Sleep -Seconds $intervalSeconds
            }
            catch {
                Write-Host "截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        
        $this.IsMonitoring = $false
        Write-Host "定時截圖已停止" -ForegroundColor Yellow
    }
    
    # 停止監控
    [void] StopMonitoring() {
        $this.IsMonitoring = $false
    }
    
    # 批次視窗截圖
    [void] BatchWindowScreenshots([string[]]$windowTitles) {
        foreach ($title in $windowTitles) {
            try {
                Write-Host "正在截取視窗: $title" -ForegroundColor Cyan
                $bitmap = $this.Core.CaptureWindow($title)
                $filename = "Window_$($title.Replace(' ', '_'))_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                $savedPath = $this.Core.SaveScreenshot($bitmap, $filename)
                $bitmap.Dispose()
                Write-Host "已儲存: $savedPath" -ForegroundColor Green
            }
            catch {
                Write-Host "截取視窗 '$title' 失敗: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # 監控特定視窗變化
    [void] MonitorWindowChanges([string]$windowTitle, [int]$intervalSeconds = 5) {
        $this.IsMonitoring = $true
        $previousHash = ""
        
        Write-Host "開始監控視窗變化: $windowTitle" -ForegroundColor Green
        
        while ($this.IsMonitoring) {
            try {
                $bitmap = $this.Core.CaptureWindow($windowTitle)
                
                # 計算圖片雜湊值來偵測變化
                $ms = New-Object System.IO.MemoryStream
                $bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
                $bytes = $ms.ToArray()
                $ms.Dispose()
                
                $hash = [System.Security.Cryptography.MD5]::Create().ComputeHash($bytes)
                $hashString = [System.BitConverter]::ToString($hash).Replace("-", "")
                
                if ($hashString -ne $previousHash -and $previousHash -ne "") {
                    $filename = "Change_$($windowTitle.Replace(' ', '_'))_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
                    $savedPath = $this.Core.SaveScreenshot($bitmap, $filename)
                    Write-Host "偵測到變化，已儲存: $savedPath" -ForegroundColor Yellow
                }
                
                $previousHash = $hashString
                $bitmap.Dispose()
                
                Start-Sleep -Seconds $intervalSeconds
            }
            catch {
                Write-Host "監控失敗: $($_.Exception.Message)" -ForegroundColor Red
                Start-Sleep -Seconds $intervalSeconds
            }
        }
        
        Write-Host "視窗監控已停止" -ForegroundColor Yellow
    }
}

# 實用工具類別
class ScreenshotUtilities {
    # 取得所有視窗清單
    static [object[]] GetAllWindows() {
        return Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | 
               Select-Object ProcessName, MainWindowTitle, Id | 
               Sort-Object MainWindowTitle
    }
    
    # 取得螢幕資訊
    static [object] GetScreenInfo() {
        $screens = [System.Windows.Forms.Screen]::AllScreens
        return $screens | ForEach-Object {
            [PSCustomObject]@{
                DeviceName = $_.DeviceName
                Primary = $_.Primary
                Bounds = $_.Bounds
                WorkingArea = $_.WorkingArea
                BitsPerPixel = $_.BitsPerPixel
            }
        }
    }
    
    # 圖片比較
    static [bool] CompareImages([string]$image1Path, [string]$image2Path) {
        if (!(Test-Path $image1Path) -or !(Test-Path $image2Path)) {
            return $false
        }
        
        $hash1 = Get-FileHash $image1Path -Algorithm MD5
        $hash2 = Get-FileHash $image2Path -Algorithm MD5
        
        return $hash1.Hash -eq $hash2.Hash
    }
    
    # 建立縮圖
    static [void] CreateThumbnail([string]$imagePath, [string]$thumbnailPath, [int]$width = 200, [int]$height = 200) {
        $originalImage = [System.Drawing.Image]::FromFile($imagePath)
        $thumbnail = $originalImage.GetThumbnailImage($width, $height, $null, [System.IntPtr]::Zero)
        
        try {
            $thumbnail.Save($thumbnailPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $originalImage.Dispose()
            $thumbnail.Dispose()
        }
    }
}

# 主要功能函式
function Show-ScreenshotMenu {
    Clear-Host
    Write-Host "=== PowerShell 截螢幕自動化範本系統 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. 全螢幕截圖" -ForegroundColor White
    Write-Host "2. 指定視窗截圖" -ForegroundColor White
    Write-Host "3. 區域截圖" -ForegroundColor White
    Write-Host "4. 批次視窗截圖" -ForegroundColor White
    Write-Host "5. 定時截圖" -ForegroundColor White
    Write-Host "6. 監控視窗變化" -ForegroundColor White
    Write-Host "7. 查看所有視窗" -ForegroundColor White
    Write-Host "8. 查看螢幕資訊" -ForegroundColor White
    Write-Host "9. 圖片比較" -ForegroundColor White
    Write-Host "10. 建立縮圖" -ForegroundColor White
    Write-Host "11. 設定配置" -ForegroundColor White
    Write-Host "12. 查看截圖記錄" -ForegroundColor White
    Write-Host "0. 離開" -ForegroundColor Red
    Write-Host ""
    Write-Host "目前截圖儲存路徑: $script:ScreenshotPath" -ForegroundColor Green
    Write-Host ""
}

function Start-FullScreenshot {
    try {
        $config = [ScreenshotConfig]::new()
        $core = [ScreenshotCore]::new($config)
        
        Write-Host "正在進行全螢幕截圖..." -ForegroundColor Cyan
        $bitmap = $core.CaptureFullScreen()
        $savedPath = $core.SaveScreenshot($bitmap)
        $bitmap.Dispose()
        
        Write-Host "全螢幕截圖已儲存: $savedPath" -ForegroundColor Green
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Start-WindowScreenshot {
    try {
        $windows = [ScreenshotUtilities]::GetAllWindows()
        
        if ($windows.Count -eq 0) {
            Write-Host "沒有找到可用的視窗" -ForegroundColor Red
            return
        }
        
        Write-Host "可用視窗清單:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $windows.Count; $i++) {
            Write-Host "$($i + 1). $($windows[$i].MainWindowTitle)" -ForegroundColor White
        }
        
        $choice = Read-Host "請選擇視窗編號 (1-$($windows.Count))"
        
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $windows.Count) {
            $selectedWindow = $windows[[int]$choice - 1]
            
            $config = [ScreenshotConfig]::new()
            $core = [ScreenshotCore]::new($config)
            
            Write-Host "正在截取視窗: $($selectedWindow.MainWindowTitle)" -ForegroundColor Cyan
            $bitmap = $core.CaptureWindow($selectedWindow.MainWindowTitle)
            $filename = "Window_$($selectedWindow.ProcessName)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $savedPath = $core.SaveScreenshot($bitmap, $filename)
            $bitmap.Dispose()
            
            Write-Host "視窗截圖已儲存: $savedPath" -ForegroundColor Green
        }
        else {
            Write-Host "無效的選擇" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Start-RegionScreenshot {
    try {
        Write-Host "請輸入截圖區域參數:" -ForegroundColor Cyan
        $x = Read-Host "X 座標"
        $y = Read-Host "Y 座標"
        $width = Read-Host "寬度"
        $height = Read-Host "高度"
        
        if ($x -match '^\d+$' -and $y -match '^\d+$' -and $width -match '^\d+$' -and $height -match '^\d+$') {
            $config = [ScreenshotConfig]::new()
            $core = [ScreenshotCore]::new($config)
            
            Write-Host "正在進行區域截圖..." -ForegroundColor Cyan
            $bitmap = $core.CaptureRegion([int]$x, [int]$y, [int]$width, [int]$height)
            $filename = "Region_$($x)x$($y)_$($width)x$($height)_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            $savedPath = $core.SaveScreenshot($bitmap, $filename)
            $bitmap.Dispose()
            
            Write-Host "區域截圖已儲存: $savedPath" -ForegroundColor Green
        }
        else {
            Write-Host "請輸入有效的數字" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Start-BatchWindowScreenshots {
    try {
        $windows = [ScreenshotUtilities]::GetAllWindows()
        
        if ($windows.Count -eq 0) {
            Write-Host "沒有找到可用的視窗" -ForegroundColor Red
            return
        }
        
        Write-Host "可用視窗清單:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $windows.Count; $i++) {
            Write-Host "$($i + 1). $($windows[$i].MainWindowTitle)" -ForegroundColor White
        }
        
        $choices = Read-Host "請選擇視窗編號 (多個用逗號分隔，例如: 1,3,5)"
        $selectedIndices = $choices.Split(',') | ForEach-Object { $_.Trim() }
        
        $selectedTitles = @()
        foreach ($index in $selectedIndices) {
            if ($index -match '^\d+$' -and [int]$index -ge 1 -and [int]$index -le $windows.Count) {
                $selectedTitles += $windows[[int]$index - 1].MainWindowTitle
            }
        }
        
        if ($selectedTitles.Count -gt 0) {
            $config = [ScreenshotConfig]::new()
            $core = [ScreenshotCore]::new($config)
            $automation = [ScreenshotAutomationManager]::new($core)
            
            Write-Host "開始批次截圖..." -ForegroundColor Cyan
            $automation.BatchWindowScreenshots($selectedTitles)
            Write-Host "批次截圖完成" -ForegroundColor Green
        }
        else {
            Write-Host "沒有選擇有效的視窗" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "批次截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Start-ScheduledScreenshots {
    try {
        $interval = Read-Host "請輸入截圖間隔 (秒)"
        $maxCount = Read-Host "請輸入最大截圖數量 (0 = 無限)"
        
        if ($interval -match '^\d+$' -and $maxCount -match '^\d+$') {
            $config = [ScreenshotConfig]::new()
            $core = [ScreenshotCore]::new($config)
            $automation = [ScreenshotAutomationManager]::new($core)
            
            Write-Host "定時截圖已啟動，按 Ctrl+C 停止" -ForegroundColor Green
            $automation.StartScheduledScreenshots([int]$interval, [int]$maxCount)
        }
        else {
            Write-Host "請輸入有效的數字" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "定時截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Start-WindowMonitoring {
    try {
        $windows = [ScreenshotUtilities]::GetAllWindows()
        
        if ($windows.Count -eq 0) {
            Write-Host "沒有找到可用的視窗" -ForegroundColor Red
            return
        }
        
        Write-Host "可用視窗清單:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $windows.Count; $i++) {
            Write-Host "$($i + 1). $($windows[$i].MainWindowTitle)" -ForegroundColor White
        }
        
        $choice = Read-Host "請選擇要監控的視窗編號 (1-$($windows.Count))"
        $interval = Read-Host "請輸入監控間隔 (秒)"
        
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $windows.Count -and $interval -match '^\d+$') {
            $selectedWindow = $windows[[int]$choice - 1]
            
            $config = [ScreenshotConfig]::new()
            $core = [ScreenshotCore]::new($config)
            $automation = [ScreenshotAutomationManager]::new($core)
            
            Write-Host "視窗監控已啟動，按 Ctrl+C 停止" -ForegroundColor Green
            $automation.MonitorWindowChanges($selectedWindow.MainWindowTitle, [int]$interval)
        }
        else {
            Write-Host "請輸入有效的選擇和數字" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "視窗監控失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-AllWindows {
    try {
        $windows = [ScreenshotUtilities]::GetAllWindows()
        
        if ($windows.Count -eq 0) {
            Write-Host "沒有找到可用的視窗" -ForegroundColor Red
        }
        else {
            Write-Host "目前所有視窗清單:" -ForegroundColor Cyan
            Write-Host "序號`t程序名稱`t`t視窗標題`t`t`t程序ID" -ForegroundColor Yellow
            Write-Host "----`t--------`t`t--------`t`t`t------" -ForegroundColor Yellow
            
            for ($i = 0; $i -lt $windows.Count; $i++) {
                $processName = $windows[$i].ProcessName.PadRight(15)
                $windowTitle = $windows[$i].MainWindowTitle
                if ($windowTitle.Length -gt 30) {
                    $windowTitle = $windowTitle.Substring(0, 30) + "..."
                }
                $windowTitle = $windowTitle.PadRight(35)
                
                Write-Host "$($i + 1)`t$processName`t$windowTitle`t$($windows[$i].Id)" -ForegroundColor White
            }
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "取得視窗清單失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-ScreenInfo {
    try {
        $screens = [ScreenshotUtilities]::GetScreenInfo()
        
        Write-Host "螢幕資訊:" -ForegroundColor Cyan
        Write-Host "========" -ForegroundColor Yellow
        
        foreach ($screen in $screens) {
            Write-Host "裝置名稱: $($screen.DeviceName)" -ForegroundColor White
            Write-Host "主要螢幕: $($screen.Primary)" -ForegroundColor White
            Write-Host "螢幕範圍: X=$($screen.Bounds.X), Y=$($screen.Bounds.Y), Width=$($screen.Bounds.Width), Height=$($screen.Bounds.Height)" -ForegroundColor White
            Write-Host "工作區域: X=$($screen.WorkingArea.X), Y=$($screen.WorkingArea.Y), Width=$($screen.WorkingArea.Width), Height=$($screen.WorkingArea.Height)" -ForegroundColor White
            Write-Host "色彩深度: $($screen.BitsPerPixel) 位元" -ForegroundColor White
            Write-Host "--------" -ForegroundColor Gray
        }
        
        Write-Host "總共 $($screens.Count) 個螢幕" -ForegroundColor Green
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "取得螢幕資訊失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Compare-Screenshots {
    try {
        Write-Host "圖片比較功能" -ForegroundColor Cyan
        $image1 = Read-Host "請輸入第一張圖片的完整路徑"
        $image2 = Read-Host "請輸入第二張圖片的完整路徑"
        
        if ((Test-Path $image1) -and (Test-Path $image2)) {
            $isIdentical = [ScreenshotUtilities]::CompareImages($image1, $image2)
            
            if ($isIdentical) {
                Write-Host "兩張圖片相同" -ForegroundColor Green
            }
            else {
                Write-Host "兩張圖片不同" -ForegroundColor Red
            }
        }
        else {
            Write-Host "找不到指定的圖片檔案" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "圖片比較失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Create-Thumbnail {
    try {
        Write-Host "建立縮圖功能" -ForegroundColor Cyan
        $sourcePath = Read-Host "請輸入原始圖片的完整路徑"
        
        if (Test-Path $sourcePath) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($sourcePath)
            $extension = [System.IO.Path]::GetExtension($sourcePath)
            $directory = [System.IO.Path]::GetDirectoryName($sourcePath)
            $thumbnailPath = Join-Path $directory "$fileName`_thumbnail$extension"
            
            $width = Read-Host "請輸入縮圖寬度 (預設: 200)"
            $height = Read-Host "請輸入縮圖高度 (預設: 200)"
            
            if ([string]::IsNullOrEmpty($width)) { $width = 200 }
            if ([string]::IsNullOrEmpty($height)) { $height = 200 }
            
            [ScreenshotUtilities]::CreateThumbnail($sourcePath, $thumbnailPath, [int]$width, [int]$height)
            Write-Host "縮圖已建立: $thumbnailPath" -ForegroundColor Green
        }
        else {
            Write-Host "找不到指定的圖片檔案" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "建立縮圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Set-ScreenshotConfig {
    try {
        $config = [ScreenshotConfig]::new()
        
        Write-Host "目前設定:" -ForegroundColor Cyan
        Write-Host "儲存路徑: $($config.DefaultPath)" -ForegroundColor White
        Write-Host "圖片格式: $($config.ImageFormat)" -ForegroundColor White
        Write-Host "品質: $($config.Quality)" -ForegroundColor White
        Write-Host "包含時間戳記: $($config.IncludeTimestamp)" -ForegroundColor White
        Write-Host "自動存檔: $($config.AutoSave)" -ForegroundColor White
        Write-Host "命名模式: $($config.NamingPattern)" -ForegroundColor White
        Write-Host ""
        
        $newPath = Read-Host "新的儲存路徑 (按 Enter 保持不變)"
        if (![string]::IsNullOrEmpty($newPath)) {
            $script:ScreenshotPath = $newPath
            if (!(Test-Path $script:ScreenshotPath)) {
                New-Item -ItemType Directory -Path $script:ScreenshotPath -Force
            }
            Write-Host "儲存路徑已更新: $script:ScreenshotPath" -ForegroundColor Green
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "設定失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Show-ScreenshotHistory {
    try {
        Write-Host "截圖記錄:" -ForegroundColor Cyan
        
        if (Test-Path $script:ScreenshotPath) {
            $files = Get-ChildItem -Path $script:ScreenshotPath -File | Sort-Object LastWriteTime -Descending
            
            if ($files.Count -eq 0) {
                Write-Host "沒有找到截圖檔案" -ForegroundColor Yellow
            }
            else {
                Write-Host "檔案名稱`t`t`t`t大小`t`t建立時間" -ForegroundColor Yellow
                Write-Host "--------`t`t`t`t----`t`t--------" -ForegroundColor Yellow
                
                foreach ($file in $files) {
                    $name = $file.Name
                    if ($name.Length -gt 40) {
                        $name = $name.Substring(0, 40) + "..."
                    }
                    $name = $name.PadRight(45)
                    
                    $size = "{0:N0} KB" -f ($file.Length / 1KB)
                    $size = $size.PadRight(15)
                    
                    $time = $file.LastWriteTime.ToString("yyyy/MM/dd HH:mm:ss")
                    
                    Write-Host "$name$size$time" -ForegroundColor White
                }
                
                Write-Host "總共 $($files.Count) 個檔案" -ForegroundColor Green
            }
        }
        else {
            Write-Host "截圖目錄不存在" -ForegroundColor Red
        }
        
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    catch {
        Write-Host "查看記錄失敗: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "按任意鍵繼續..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# 主程式
function Start-ScreenshotSystem {
    Write-Host "正在初始化 PowerShell 截螢幕自動化系統..." -ForegroundColor Green
    
    # 初始化設定
    $config = [ScreenshotConfig]::new()
    
    do {
        Show-ScreenshotMenu
        $choice = Read-Host "請選擇功能 (0-12)"
        
        switch ($choice) {
            "1" { Start-FullScreenshot }
            "2" { Start-WindowScreenshot }
            "3" { Start-RegionScreenshot }
            "4" { Start-BatchWindowScreenshots }
            "5" { Start-ScheduledScreenshots }
            "6" { Start-WindowMonitoring }
            "7" { Show-AllWindows }
            "8" { Show-ScreenInfo }
            "9" { Compare-Screenshots }
            "10" { Create-Thumbnail }
            "11" { Set-ScreenshotConfig }
            "12" { Show-ScreenshotHistory }
            "0" { 
                Write-Host "感謝使用 PowerShell 截螢幕自動化系統！" -ForegroundColor Green
                break
            }
            default { 
                Write-Host "無效的選擇，請重新輸入" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($choice -ne "0")
}

# 快速截圖函式 (可直接調用)
function Quick-FullScreenshot {
    param([string]$OutputPath = "")
    
    try {
        $config = [ScreenshotConfig]::new()
        if (![string]::IsNullOrEmpty($OutputPath)) {
            $config.DefaultPath = $OutputPath
        }
        
        $core = [ScreenshotCore]::new($config)
        $bitmap = $core.CaptureFullScreen()
        $savedPath = $core.SaveScreenshot($bitmap)
        $bitmap.Dispose()
        
        Write-Host "快速截圖已儲存: $savedPath" -ForegroundColor Green
        return $savedPath
    }
    catch {
        Write-Host "快速截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Quick-WindowScreenshot {
    param(
        [string]$WindowTitle,
        [string]$OutputPath = ""
    )
    
    try {
        $config = [ScreenshotConfig]::new()
        if (![string]::IsNullOrEmpty($OutputPath)) {
            $config.DefaultPath = $OutputPath
        }
        
        $core = [ScreenshotCore]::new($config)
        $bitmap = $core.CaptureWindow($WindowTitle)
        $filename = "Window_$($WindowTitle.Replace(' ', '_'))_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        $savedPath = $core.SaveScreenshot($bitmap, $filename)
        $bitmap.Dispose()
        
        Write-Host "視窗截圖已儲存: $savedPath" -ForegroundColor Green
        return $savedPath
    }
    catch {
        Write-Host "視窗截圖失敗: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# 幫助資訊
function Show-ScreenshotHelp {
    Write-Host "=== PowerShell 截螢幕自動化範本系統 幫助 ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "主要功能:" -ForegroundColor Yellow
    Write-Host "1. Start-ScreenshotSystem     - 啟動互動式主選單" -ForegroundColor White
    Write-Host "2. Quick-FullScreenshot       - 快速全螢幕截圖" -ForegroundColor White
    Write-Host "3. Quick-WindowScreenshot     - 快速視窗截圖" -ForegroundColor White
    Write-Host "4. Show-ScreenshotHelp        - 顯示此幫助資訊" -ForegroundColor White
    Write-Host ""
    Write-Host "使用範例:" -ForegroundColor Yellow
    Write-Host "Quick-FullScreenshot" -ForegroundColor Green
    Write-Host "Quick-WindowScreenshot -WindowTitle 'Chrome'" -ForegroundColor Green
    Write-Host "Quick-WindowScreenshot -WindowTitle 'Notepad' -OutputPath 'C:\Screenshots'" -ForegroundColor Green
    Write-Host ""
    Write-Host "全域變數:" -ForegroundColor Yellow
    Write-Host "`$script:ScreenshotPath - 預設截圖儲存路徑" -ForegroundColor White
    Write-Host "`$script:LogPath - 日誌檔案路徑" -ForegroundColor White
    Write-Host ""
}

# 歡迎訊息
Write-Host "=== PowerShell 截螢幕自動化範本系統已載入 ===" -ForegroundColor Green
Write-Host "輸入 'Start-ScreenshotSystem' 開始使用" -ForegroundColor Cyan
Write-Host "輸入 'Show-ScreenshotHelp' 查看說明" -ForegroundColor Cyan
Write-Host "截圖儲存路徑: $script:ScreenshotPath" -ForegroundColor Yellow
Write-Host ""

# 自動啟動 (可選)
# Start-ScreenshotSystem
