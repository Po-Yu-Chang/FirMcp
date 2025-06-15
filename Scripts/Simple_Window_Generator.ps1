# Simple Random Window Generator - Clean Version
# 簡化版隨機視窗產生器

param(
    [int]$WindowCount = 1,
    [string]$WindowPrefix = "MCP_Test"
)

Write-Host "=== Simple Random Window Generator ===" -ForegroundColor Cyan
Write-Host "Creating $WindowCount test windows..." -ForegroundColor Yellow

# Load Windows Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Button texts
$ButtonTexts = @(
    "OK", "Cancel", "Apply", "Reset", "Save", "Load", "Export", "Import",
    "Start", "Stop", "Pause", "Continue", "Retry", "Skip", "Finish", "Close",
    "Add", "Delete", "Edit", "Copy", "Move", "Search", "Filter", "Sort",
    "Settings", "Tools", "Help", "About", "Login", "Logout", "Register", "Update"
)

$ButtonColors = @(
    [System.Drawing.Color]::LightBlue,
    [System.Drawing.Color]::LightGreen,
    [System.Drawing.Color]::LightCoral,
    [System.Drawing.Color]::LightGoldenrodYellow,
    [System.Drawing.Color]::LightPink,
    [System.Drawing.Color]::LightSalmon
)

# Store windows
$Windows = @()

for ($i = 1; $i -le $WindowCount; $i++) {
    Write-Host "Creating window $i..." -ForegroundColor Green
    
    # Create main form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "$WindowPrefix $i - Button Test Window"
    $form.Size = New-Object System.Drawing.Size(500, 400)
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.BackColor = [System.Drawing.Color]::WhiteSmoke
    
    # Add title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "MCP Screenshot Test Window #$i"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::DarkBlue
    $titleLabel.Location = New-Object System.Drawing.Point(20, 20)
    $titleLabel.Size = New-Object System.Drawing.Size(400, 30)
    $form.Controls.Add($titleLabel)
    
    # Add info label
    $infoLabel = New-Object System.Windows.Forms.Label
    $infoLabel.Text = "This window contains random buttons for MCP testing"
    $infoLabel.Font = New-Object System.Drawing.Font("Arial", 9)
    $infoLabel.ForeColor = [System.Drawing.Color]::Gray
    $infoLabel.Location = New-Object System.Drawing.Point(20, 55)
    $infoLabel.Size = New-Object System.Drawing.Size(400, 20)
    $form.Controls.Add($infoLabel)
    
    # Create buttons
    $buttonCount = Get-Random -Min 4 -Max 7
    Write-Host "  Creating $buttonCount buttons" -ForegroundColor Cyan
    
    for ($j = 0; $j -lt $buttonCount; $j++) {
        $button = New-Object System.Windows.Forms.Button
        
        # Random button text
        $randomText = $ButtonTexts | Get-Random
        $button.Text = $randomText
        
        # Calculate position
        $row = [Math]::Floor($j / 3)
        $col = $j % 3
        $x = 30 + ($col * 130)
        $y = 90 + ($row * 50)
        
        $button.Location = New-Object System.Drawing.Point($x, $y)
        $button.Size = New-Object System.Drawing.Size(120, 40)
        
        # Random color
        $button.BackColor = $ButtonColors | Get-Random
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.Font = New-Object System.Drawing.Font("Arial", 9)
        
        # Add click event
        $button.Add_Click({
            $clickedButton = $this
            Write-Host "Button clicked: $($clickedButton.Text)" -ForegroundColor Green
            [System.Windows.Forms.MessageBox]::Show("You clicked: $($clickedButton.Text)", "Button Test")
        })
        
        $form.Controls.Add($button)
    }
    
    # Add close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close Window"
    $closeButton.BackColor = [System.Drawing.Color]::LightCoral
    $closeButton.Location = New-Object System.Drawing.Point(350, 320)
    $closeButton.Size = New-Object System.Drawing.Size(100, 30)
    $closeButton.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($closeButton)
    
    # Store window info
    $windowInfo = @{
        Form = $form
        ButtonCount = $buttonCount
        WindowTitle = $form.Text
    }
    $Windows += $windowInfo
    
    Write-Host "  Window $i created successfully ($buttonCount buttons)" -ForegroundColor Green
}

# Show windows
Write-Host ""
Write-Host "=== Window Information ===" -ForegroundColor Cyan
foreach ($window in $Windows) {
    Write-Host "Window: $($window.WindowTitle)" -ForegroundColor Yellow
    Write-Host "  - Button count: $($window.ButtonCount)" -ForegroundColor Gray
    Write-Host "  - Window size: $($window.Form.Size.Width) x $($window.Form.Size.Height)" -ForegroundColor Gray
    
    # Show window
    $window.Form.Show()
}

Write-Host ""
Write-Host "=== Test Instructions ===" -ForegroundColor Cyan
Write-Host "1. Now you can use MCP screenshot tool to capture these windows" -ForegroundColor White
Write-Host "2. Test automatic button detection" -ForegroundColor White
Write-Host "3. Verify annotation functionality" -ForegroundColor White
Write-Host ""
Write-Host "Suggested test command:" -ForegroundColor Yellow
Write-Host "  Smart_Button_Screenshot.ps1 -WindowTitle `"$($Windows[0].WindowTitle)`" -OutputPrefix `"button_test`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to close all windows..." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Close all windows
Write-Host "Closing all test windows..." -ForegroundColor Yellow
foreach ($window in $Windows) {
    $window.Form.Close()
    $window.Form.Dispose()
}

Write-Host "All test windows closed" -ForegroundColor Green
