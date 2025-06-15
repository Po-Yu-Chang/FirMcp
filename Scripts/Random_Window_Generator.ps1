# Random GUI Window Generator
# 隨機視窗產生器 - 用於測試 MCP 截圖功能

param(
    [int]$WindowCount = 1,
    [int]$MinButtons = 3,
    [int]$MaxButtons = 8,
    [string]$WindowPrefix = "TestWindow"
)

Write-Host "=== 隨機視窗產生器 ===" -ForegroundColor Cyan
Write-Host "即將建立 $WindowCount 個測試視窗" -ForegroundColor Yellow

# 載入 Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 定義隨機按鈕樣式
$ButtonTexts = @(
    "確定", "取消", "套用", "重設", "儲存", "載入", "匯出", "匯入",
    "開始", "停止", "暫停", "繼續", "重試", "跳過", "完成", "關閉",
    "新增", "刪除", "編輯", "複製", "移動", "搜尋", "篩選", "排序",
    "設定", "工具", "說明", "關於", "登入", "登出", "註冊", "更新"
)

$ButtonColors = @(
    [System.Drawing.Color]::LightBlue,
    [System.Drawing.Color]::LightGreen,
    [System.Drawing.Color]::LightCoral,
    [System.Drawing.Color]::LightGoldenrodYellow,
    [System.Drawing.Color]::LightPink,
    [System.Drawing.Color]::LightSalmon,
    [System.Drawing.Color]::LightSteelBlue,
    [System.Drawing.Color]::LightCyan
)

# 儲存視窗參考
$Windows = @()

for ($i = 1; $i -le $WindowCount; $i++) {
    Write-Host "建立視窗 $i..." -ForegroundColor Green
    
    # 建立主視窗
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$WindowPrefix $i - 按鈕測試視窗"
    $form.Size = New-Object System.Drawing.Size($(Get-Random -Min 400 -Max 600), $(Get-Random -Min 300 -Max 500))
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    
    # 隨機位置
    $form.Location = New-Object System.Drawing.Point($(Get-Random -Min 50 -Max 500), $(Get-Random -Min 50 -Max 300))
    $form.BackColor = [System.Drawing.Color]::WhiteSmoke
    
    # 添加標題標籤
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "MCP 截圖測試視窗 #$i"
    $titleLabel.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(300, 30)
    $form.Controls.Add($titleLabel)
    
    # 添加說明標籤
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "此視窗包含隨機按鈕，用於測試 MCP 自動識別功能"
    $infoLabel.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 9)
    $infoLabel.ForeColor = [System.Drawing.Color]::Gray
    $infoLabel.Location = New-Object System.Drawing.Point(20, 55)
    $infoLabel.Size = New-Object System.Drawing.Size(350, 20)
    $form.Controls.Add($infoLabel)
    
    # 隨機按鈕數量
    $buttonCount = Get-Random -Min $MinButtons -Max $MaxButtons
    $buttonsPerRow = [Math]::Ceiling([Math]::Sqrt($buttonCount))
    
    Write-Host "  - 將建立 $buttonCount 個按鈕" -ForegroundColor Cyan
    
    # 建立按鈕
    for ($j = 0; $j -lt $buttonCount; $j++) {
        $button = New-Object System.Windows.Forms.Button
        
        # 隨機按鈕文字
        $randomText = $ButtonTexts | Get-Random
        $button.Text = $randomText
        
        # 計算按鈕位置
        $row = [Math]::Floor($j / $buttonsPerRow)
        $col = $j % $buttonsPerRow
        $x = 30 + ($col * 120)
        $y = 90 + ($row * 50)
        
        $button.Location = New-Object System.Drawing.Point($x, $y)
        $button.Size = New-Object System.Drawing.Size(100, 35)
        
        # 隨機顏色
        $button.BackColor = $ButtonColors | Get-Random
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.Font = New-Object System.Drawing.Font("Microsoft JhengHei", 9)
        
        # 添加點擊事件
        $button.Add_Click({
            $clickedButton = $this
            Write-Host "按鈕被點擊: $($clickedButton.Text)" -ForegroundColor Green
            [System.Windows.Forms.MessageBox]::Show("您點擊了按鈕: $($clickedButton.Text)", "按鈕測試", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        })
        
        $form.Controls.Add($button)
    }
    
    # 添加關閉按鈕
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "關閉視窗"
    $closeButton.BackColor = [System.Drawing.Color]::LightCoral
    $closeButton.Location = New-Object System.Drawing.Point(($form.Width - 120), ($form.Height - 80))
    $closeButton.Size = New-Object System.Drawing.Size(80, 30)
    $closeButton.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($closeButton)
    
    # 儲存視窗資訊
    $windowInfo = @{
        Form = $form
        ProcessName = "$WindowPrefix$i"
        ButtonCount = $buttonCount
        WindowTitle = $form.Text
    }
    $Windows += $windowInfo
    
    Write-Host "  ✅ 視窗 $i 建立完成 ($buttonCount 個按鈕)" -ForegroundColor Green
}

# 顯示視窗
Write-Host ""
Write-Host "=== 視窗資訊 ===" -ForegroundColor Cyan
foreach ($window in $Windows) {
    Write-Host "視窗: $($window.WindowTitle)" -ForegroundColor Yellow
    Write-Host "  - 按鈕數量: $($window.ButtonCount)" -ForegroundColor Gray
    Write-Host "  - 視窗大小: $($window.Form.Size.Width) x $($window.Form.Size.Height)" -ForegroundColor Gray
    
    # 非同步顯示視窗
    $window.Form.Show()
}

Write-Host ""
Write-Host "=== 測試說明 ===" -ForegroundColor Cyan
Write-Host "1. 現在可以使用 MCP 截圖工具來截取這些視窗" -ForegroundColor White
Write-Host "2. 測試自動按鈕識別功能" -ForegroundColor White
Write-Host "3. 驗證標註功能是否正確" -ForegroundColor White
Write-Host ""
Write-Host "建議的測試指令:" -ForegroundColor Yellow
Write-Host "  # 使用 MCP 截圖工具" -ForegroundColor Gray
Write-Host "  .\Scripts\Universal_Clean_Screenshot.ps1 -WindowTitle `"$($Windows[0].WindowTitle)`" -OutputPrefix `"random_test`"" -ForegroundColor Gray
Write-Host ""
Write-Host "按任意鍵關閉所有視窗..." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 關閉所有視窗
Write-Host "正在關閉所有測試視窗..." -ForegroundColor Yellow
foreach ($window in $Windows) {
    $window.Form.Close()
    $window.Form.Dispose()
}

Write-Host "所有測試視窗已關閉" -ForegroundColor Green
