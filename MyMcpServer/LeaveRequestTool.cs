using ModelContextProtocol.Server;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;

[McpServerToolType]
public static class ScreenshotTool
{
    private static readonly string ScreenshotPath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Desktop), "Screenshots");
    private static readonly string PowerShellScriptPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "..", "Support", "PowerShell_Screenshot_Automation.ps1");

    static ScreenshotTool()
    {
        // 確保截圖目錄存在
        if (!Directory.Exists(ScreenshotPath))
        {
            Directory.CreateDirectory(ScreenshotPath);
        }
    }

    [McpServerTool, Description("擷取全螢幕截圖")]
    public static string CaptureFullScreen([Description("截圖檔案名稱（可選，不含副檔名）")] string fileName = "")
    {
        try
        {
            return ExecutePowerShellScript("Quick-FullScreenshot", new Dictionary<string, object>
            {
                { "OutputPath", ScreenshotPath }
            });
        }
        catch (Exception ex)
        {
            return $"全螢幕截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("擷取指定視窗截圖")]
    public static string CaptureWindow([Description("視窗標題（部分匹配）")] string windowTitle, [Description("截圖檔案名稱（可選，不含副檔名）")] string fileName = "")
    {
        try
        {
            return ExecutePowerShellScript("Quick-WindowScreenshot", new Dictionary<string, object>
            {
                { "WindowTitle", windowTitle },
                { "OutputPath", ScreenshotPath }
            });
        }
        catch (Exception ex)
        {
            return $"視窗截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("擷取螢幕區域截圖")]
    public static string CaptureRegion(
        [Description("X 座標")] int x,
        [Description("Y 座標")] int y,
        [Description("寬度")] int width,
        [Description("高度")] int height,
        [Description("截圖檔案名稱（可選，不含副檔名）")] string fileName = "")
    {
        try
        {
            using var bitmap = new Bitmap(width, height);
            using var graphics = Graphics.FromImage(bitmap);
            graphics.CopyFromScreen(x, y, 0, 0, new Size(width, height));
            
            if (string.IsNullOrEmpty(fileName))
            {
                fileName = $"Region_{x}x{y}_{width}x{height}_{DateTime.Now:yyyyMMdd_HHmmss}";
            }
            
            var fullPath = Path.Combine(ScreenshotPath, $"{fileName}.png");
            bitmap.Save(fullPath, ImageFormat.Png);
            
            return $"區域截圖已儲存: {fullPath}";
        }
        catch (Exception ex)
        {
            return $"區域截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("在截圖上標記重點並新增說明")]
    public static string AnnotateScreenshot(
        [Description("截圖檔案路徑")] string imagePath,
        [Description("標記類型：circle（圓圈）、rectangle（矩形）、arrow（箭頭）、text（文字）")] string annotationType,
        [Description("X 座標")] int x,
        [Description("Y 座標")] int y,
        [Description("寬度（僅矩形）")] int width = 100,
        [Description("高度（僅矩形）")] int height = 50,
        [Description("標記文字或說明")] string text = "",
        [Description("標記顏色（red, blue, green, yellow, black）")] string color = "red")
    {
        try
        {
            if (!File.Exists(imagePath))
            {
                return $"找不到圖片檔案: {imagePath}";
            }

            using var image = new Bitmap(imagePath);
            using var graphics = Graphics.FromImage(image);
            
            // 設定畫筆顏色
            var penColor = GetColor(color);
            using var pen = new Pen(penColor, 3);
            using var brush = new SolidBrush(penColor);
            using var font = new Font("Microsoft JhengHei", 12, FontStyle.Bold);

            switch (annotationType.ToLower())
            {
                case "circle":
                    graphics.DrawEllipse(pen, x - 25, y - 25, 50, 50);
                    break;
                    
                case "rectangle":
                    graphics.DrawRectangle(pen, x, y, width, height);
                    break;
                    
                case "arrow":
                    DrawArrow(graphics, pen, x, y, x + 50, y + 50);
                    break;
                    
                case "text":
                    if (!string.IsNullOrEmpty(text))
                    {
                        graphics.DrawString(text, font, brush, x, y);
                    }
                    break;
                    
                default:
                    return $"不支援的標記類型: {annotationType}";
            }

            // 如果有文字說明且不是純文字標記，在標記旁邊加上文字
            if (!string.IsNullOrEmpty(text) && annotationType.ToLower() != "text")
            {
                graphics.DrawString(text, font, brush, x + 60, y - 10);
            }            // 儲存標記後的圖片
            var fileName = Path.GetFileNameWithoutExtension(imagePath);
            var extension = Path.GetExtension(imagePath);
            var directory = Path.GetDirectoryName(imagePath) ?? ScreenshotPath;
            var annotatedPath = Path.Combine(directory, $"{fileName}_annotated{extension}");
            
            image.Save(annotatedPath, ImageFormat.Png);
            
            return $"已在截圖上新增{annotationType}標記並儲存至: {annotatedPath}";
        }
        catch (Exception ex)
        {
            return $"標記截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("分析螢幕截圖內容並提供說明")]
    public static string AnalyzeScreenshot([Description("截圖檔案路徑")] string imagePath)
    {
        try
        {
            if (!File.Exists(imagePath))
            {
                return $"找不到圖片檔案: {imagePath}";
            }

            var fileInfo = new FileInfo(imagePath);
            using var image = new Bitmap(imagePath);
            
            var analysis = new StringBuilder();
            analysis.AppendLine("=== 螢幕截圖分析報告 ===");
            analysis.AppendLine($"檔案路徑: {imagePath}");
            analysis.AppendLine($"檔案大小: {fileInfo.Length / 1024:N0} KB");
            analysis.AppendLine($"影像尺寸: {image.Width} x {image.Height} 像素");
            analysis.AppendLine($"像素格式: {image.PixelFormat}");
            analysis.AppendLine($"建立時間: {fileInfo.CreationTime:yyyy-MM-dd HH:mm:ss}");
            analysis.AppendLine();
            
            // 簡單的顏色分析
            var colorAnalysis = AnalyzeImageColors(image);
            analysis.AppendLine("=== 顏色分析 ===");
            analysis.AppendLine(colorAnalysis);
            analysis.AppendLine();
            
            // 區域建議
            analysis.AppendLine("=== 標記建議 ===");
            analysis.AppendLine("建議在以下區域進行重點標記：");
            analysis.AppendLine($"• 左上角區域 (0, 0) - 通常是標題或選單");
            analysis.AppendLine($"• 中央區域 ({image.Width/2-100}, {image.Height/2-50}) - 主要內容區");
            analysis.AppendLine($"• 右下角區域 ({image.Width-200}, {image.Height-100}) - 狀態或按鈕區");
            
            return analysis.ToString();
        }
        catch (Exception ex)
        {
            return $"分析截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("取得目前所有視窗清單")]
    public static string GetAllWindows()
    {
        try
        {
            var processes = Process.GetProcesses()
                .Where(p => !string.IsNullOrEmpty(p.MainWindowTitle))
                .Select(p => new { ProcessName = p.ProcessName, WindowTitle = p.MainWindowTitle, Id = p.Id })
                .OrderBy(p => p.WindowTitle)
                .ToList();

            if (!processes.Any())
            {
                return "沒有找到可用的視窗";
            }

            var result = new StringBuilder();
            result.AppendLine("=== 目前所有視窗清單 ===");
            result.AppendLine("程序名稱\t\t視窗標題\t\t\t程序ID");
            result.AppendLine("--------\t\t--------\t\t\t------");
            
            foreach (var process in processes)
            {
                var processName = process.ProcessName.Length > 15 ? process.ProcessName.Substring(0, 15) : process.ProcessName;
                var windowTitle = process.WindowTitle.Length > 30 ? process.WindowTitle.Substring(0, 30) + "..." : process.WindowTitle;
                result.AppendLine($"{processName.PadRight(15)}\t{windowTitle.PadRight(35)}\t{process.Id}");
            }

            return result.ToString();
        }
        catch (Exception ex)
        {
            return $"取得視窗清單失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("取得目前日期時間")]
    public static string GetCurrentDateTime()
    {
        return DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
    }    // 輔助方法
    private static string ExecutePowerShellScript(string functionName, Dictionary<string, object>? parameters = null)
    {
        try
        {
            using var process = new Process();
            process.StartInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true
            };

            var script = new StringBuilder();
            script.AppendLine($". '{PowerShellScriptPath}'");
            
            if (parameters != null && parameters.Any())
            {
                var paramString = string.Join(" ", parameters.Select(p => $"-{p.Key} '{p.Value}'"));
                script.AppendLine($"{functionName} {paramString}");
            }
            else
            {
                script.AppendLine(functionName);
            }

            process.StartInfo.Arguments = $"-Command \"{script}\"";
            process.Start();

            var output = process.StandardOutput.ReadToEnd();
            var error = process.StandardError.ReadToEnd();
            process.WaitForExit();

            if (process.ExitCode == 0)
            {
                return string.IsNullOrEmpty(output) ? "執行成功" : output.Trim();
            }
            else
            {
                return $"執行失敗: {error}";
            }
        }
        catch (Exception ex)
        {
            return $"PowerShell 執行錯誤: {ex.Message}";
        }
    }

    private static Color GetColor(string colorName)
    {
        return colorName.ToLower() switch
        {
            "red" => Color.Red,
            "blue" => Color.Blue,
            "green" => Color.Green,
            "yellow" => Color.Yellow,
            "black" => Color.Black,
            "white" => Color.White,
            "orange" => Color.Orange,
            "purple" => Color.Purple,
            _ => Color.Red
        };
    }

    private static void DrawArrow(Graphics graphics, Pen pen, int x1, int y1, int x2, int y2)
    {
        // 畫線
        graphics.DrawLine(pen, x1, y1, x2, y2);
        
        // 計算箭頭頭部
        var angle = Math.Atan2(y2 - y1, x2 - x1);
        var arrowLength = 10;
        var arrowAngle = Math.PI / 6; // 30度
        
        var x3 = (int)(x2 - arrowLength * Math.Cos(angle - arrowAngle));
        var y3 = (int)(y2 - arrowLength * Math.Sin(angle - arrowAngle));
        var x4 = (int)(x2 - arrowLength * Math.Cos(angle + arrowAngle));
        var y4 = (int)(y2 - arrowLength * Math.Sin(angle + arrowAngle));
        
        // 畫箭頭頭部
        graphics.DrawLine(pen, x2, y2, x3, y3);
        graphics.DrawLine(pen, x2, y2, x4, y4);
    }

    private static string AnalyzeImageColors(Bitmap image)
    {
        var colorCount = new Dictionary<Color, int>();
        var sampleSize = Math.Min(image.Width * image.Height, 10000); // 限制取樣數量以提高效能
        var random = new Random();
        
        for (int i = 0; i < sampleSize; i++)
        {
            var x = random.Next(image.Width);
            var y = random.Next(image.Height);
            var color = image.GetPixel(x, y);
            
            // 簡化顏色以減少複雜度
            var simplifiedColor = Color.FromArgb(
                (color.R / 50) * 50,
                (color.G / 50) * 50,
                (color.B / 50) * 50
            );
            
            colorCount[simplifiedColor] = colorCount.GetValueOrDefault(simplifiedColor, 0) + 1;
        }
        
        var topColors = colorCount.OrderByDescending(kv => kv.Value).Take(5).ToList();
        var result = new StringBuilder();
        result.AppendLine("主要顏色分佈：");
        
        foreach (var colorInfo in topColors)
        {
            var percentage = (double)colorInfo.Value / sampleSize * 100;
            result.AppendLine($"• RGB({colorInfo.Key.R}, {colorInfo.Key.G}, {colorInfo.Key.B}) - {percentage:F1}%");
        }
        
        return result.ToString();
    }

    [McpServerTool, Description("批次截圖多個視窗")]
    public static string BatchCaptureWindows([Description("視窗標題清單，用逗號分隔")] string windowTitles)
    {
        try
        {
            var titles = windowTitles.Split(',', StringSplitOptions.RemoveEmptyEntries)
                                   .Select(t => t.Trim())
                                   .ToArray();
            
            var results = new StringBuilder();
            results.AppendLine("=== 批次視窗截圖結果 ===");
            
            foreach (var title in titles)
            {
                try
                {
                    var result = CaptureWindow(title);
                    results.AppendLine($"✓ {title}: {result}");
                }
                catch (Exception ex)
                {
                    results.AppendLine($"✗ {title}: 失敗 - {ex.Message}");
                }
            }
            
            return results.ToString();
        }
        catch (Exception ex)
        {
            return $"批次截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("建立螢幕截圖的縮圖")]
    public static string CreateScreenshotThumbnail(
        [Description("原始圖片路徑")] string imagePath,
        [Description("縮圖寬度")] int width = 200,
        [Description("縮圖高度")] int height = 200)
    {
        try
        {
            if (!File.Exists(imagePath))
            {
                return $"找不到圖片檔案: {imagePath}";
            }

            using var originalImage = new Bitmap(imagePath);
            using var thumbnail = new Bitmap(width, height);
            using var graphics = Graphics.FromImage(thumbnail);
            
            graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBicubic;
            graphics.DrawImage(originalImage, 0, 0, width, height);
            
            var fileName = Path.GetFileNameWithoutExtension(imagePath);
            var extension = Path.GetExtension(imagePath);
            var directory = Path.GetDirectoryName(imagePath) ?? ScreenshotPath;
            var thumbnailPath = Path.Combine(directory, $"{fileName}_thumbnail{extension}");
            
            thumbnail.Save(thumbnailPath, ImageFormat.Png);
            
            return $"縮圖已建立: {thumbnailPath}";
        }
        catch (Exception ex)
        {
            return $"建立縮圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("比較兩張截圖是否相同")]
    public static string CompareScreenshots(
        [Description("第一張圖片路徑")] string imagePath1,
        [Description("第二張圖片路徑")] string imagePath2)
    {
        try
        {
            if (!File.Exists(imagePath1) || !File.Exists(imagePath2))
            {
                return "找不到指定的圖片檔案";
            }

            var hash1 = GetImageHash(imagePath1);
            var hash2 = GetImageHash(imagePath2);
            
            var result = new StringBuilder();
            result.AppendLine("=== 圖片比較結果 ===");
            result.AppendLine($"圖片1: {Path.GetFileName(imagePath1)}");
            result.AppendLine($"圖片2: {Path.GetFileName(imagePath2)}");
            result.AppendLine($"雜湊值1: {hash1}");
            result.AppendLine($"雜湊值2: {hash2}");
            
            if (hash1 == hash2)
            {
                result.AppendLine("結果: ✓ 兩張圖片相同");
            }
            else
            {
                result.AppendLine("結果: ✗ 兩張圖片不同");
            }
            
            return result.ToString();
        }
        catch (Exception ex)
        {
            return $"比較圖片失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("定時截圖功能")]
    public static string StartTimedScreenshots(
        [Description("截圖間隔（秒）")] int intervalSeconds,
        [Description("最大截圖數量")] int maxCount = 5)
    {
        try
        {
            var results = new StringBuilder();
            results.AppendLine($"=== 定時截圖開始 ===");
            results.AppendLine($"間隔: {intervalSeconds} 秒");
            results.AppendLine($"最大數量: {maxCount}");
            results.AppendLine();
            
            for (int i = 1; i <= maxCount; i++)
            {
                var fileName = $"Timed_{i:D2}_{DateTime.Now:yyyyMMdd_HHmmss}";
                var result = CaptureFullScreen(fileName);
                results.AppendLine($"第 {i} 張: {result}");
                
                if (i < maxCount)
                {
                    Thread.Sleep(intervalSeconds * 1000);
                }
            }
            
            results.AppendLine();
            results.AppendLine("=== 定時截圖完成 ===");
            return results.ToString();
        }
        catch (Exception ex)
        {
            return $"定時截圖失敗: {ex.Message}";
        }
    }

    [McpServerTool, Description("擷取螢幕特定應用程式視窗")]
    public static string CaptureApplicationWindow([Description("應用程式名稱（如：notepad、chrome、code）")] string applicationName)
    {
        try
        {
            var processes = Process.GetProcesses()
                .Where(p => p.ProcessName.ToLower().Contains(applicationName.ToLower()) && 
                           !string.IsNullOrEmpty(p.MainWindowTitle))
                .ToList();

            if (!processes.Any())
            {
                return $"找不到應用程式: {applicationName}";
            }

            var results = new StringBuilder();
            results.AppendLine($"=== 應用程式 '{applicationName}' 視窗截圖 ===");
            
            foreach (var process in processes.Take(3)) // 限制最多3個視窗
            {
                try
                {
                    var result = CaptureWindow(process.MainWindowTitle);
                    results.AppendLine($"✓ {process.MainWindowTitle}: {result}");
                }
                catch (Exception ex)
                {
                    results.AppendLine($"✗ {process.MainWindowTitle}: 失敗 - {ex.Message}");
                }
            }
            
            return results.ToString();
        }
        catch (Exception ex)
        {
            return $"擷取應用程式視窗失敗: {ex.Message}";
        }
    }

    private static string GetImageHash(string imagePath)
    {
        using var image = new Bitmap(imagePath);
        using var ms = new MemoryStream();
        image.Save(ms, ImageFormat.Png);
        var bytes = ms.ToArray();
        
        using var md5 = System.Security.Cryptography.MD5.Create();
        var hash = md5.ComputeHash(bytes);
        return Convert.ToHexString(hash);
    }
}
