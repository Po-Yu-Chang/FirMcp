# MCP 螢幕截圖伺服器使用說明

## 概述
這是一個基於 Model Context Protocol (MCP) 的螢幕截圖自動化伺服器，提供全方位的螢幕截圖、標註和分析功能。

## 功能特色

### 🖥️ 螢幕截圖功能
1. **全螢幕截圖** - 擷取完整螢幕內容
2. **視窗截圖** - 針對特定視窗進行截圖
3. **區域截圖** - 擷取螢幕指定區域
4. **批次截圖** - 同時截取多個視窗
5. **定時截圖** - 按時間間隔自動截圖
6. **應用程式截圖** - 根據應用程式名稱截圖

### 🎨 圖片標註功能
1. **圓圈標記** - 在重要位置畫圓圈
2. **矩形標記** - 框選重要區域
3. **箭頭標記** - 指向特定位置
4. **文字標記** - 新增說明文字
5. **多色標記** - 支援多種顏色選擇

### 📊 圖片分析功能
1. **圖片分析** - 提供詳細的圖片資訊
2. **顏色分析** - 分析主要顏色分佈
3. **圖片比較** - 比較兩張圖片是否相同
4. **縮圖建立** - 建立圖片縮圖
5. **視窗清單** - 取得所有可用視窗

## 可用的 MCP 工具

### 基本截圖工具

#### 🔸 CaptureFullScreen
```
描述: 擷取全螢幕截圖
參數: 
- fileName (可選): 截圖檔案名稱（不含副檔名）
```

#### 🔸 CaptureWindow
```
描述: 擷取指定視窗截圖
參數:
- windowTitle: 視窗標題（支援部分匹配）
- fileName (可選): 截圖檔案名稱（不含副檔名）
```

#### 🔸 CaptureRegion
```
描述: 擷取螢幕區域截圖
參數:
- x: X 座標
- y: Y 座標  
- width: 寬度
- height: 高度
- fileName (可選): 截圖檔案名稱（不含副檔名）
```

### 進階截圖工具

#### 🔸 BatchCaptureWindows
```
描述: 批次截圖多個視窗
參數:
- windowTitles: 視窗標題清單，用逗號分隔
```

#### 🔸 CaptureApplicationWindow
```
描述: 擷取螢幕特定應用程式視窗
參數:
- applicationName: 應用程式名稱（如：notepad、chrome、code）
```

#### 🔸 StartTimedScreenshots
```
描述: 定時截圖功能
參數:
- intervalSeconds: 截圖間隔（秒）
- maxCount: 最大截圖數量（預設5）
```

### 圖片標註工具

#### 🔸 AnnotateScreenshot
```
描述: 在截圖上標記重點並新增說明
參數:
- imagePath: 截圖檔案路徑
- annotationType: 標記類型（circle、rectangle、arrow、text）
- x: X 座標
- y: Y 座標
- width: 寬度（僅矩形）
- height: 高度（僅矩形）
- text: 標記文字或說明
- color: 標記顏色（red、blue、green、yellow、black）
```

### 分析工具

#### 🔸 AnalyzeScreenshot
```
描述: 分析螢幕截圖內容並提供說明
參數:
- imagePath: 截圖檔案路徑
```

#### 🔸 CompareScreenshots
```
描述: 比較兩張截圖是否相同
參數:
- imagePath1: 第一張圖片路徑
- imagePath2: 第二張圖片路徑
```

#### 🔸 CreateScreenshotThumbnail
```
描述: 建立螢幕截圖的縮圖
參數:
- imagePath: 原始圖片路徑
- width: 縮圖寬度（預設200）
- height: 縮圖高度（預設200）
```

### 系統工具

#### 🔸 GetAllWindows
```
描述: 取得目前所有視窗清單
參數: 無
```

#### 🔸 GetCurrentDateTime
```
描述: 取得目前日期時間
參數: 無
```

## 使用範例

### 範例 1: 基本螢幕截圖
```
1. 執行 CaptureFullScreen 進行全螢幕截圖
2. 執行 CaptureWindow，windowTitle = "記事本" 截取記事本視窗
```

### 範例 2: 標註重點
```
1. 先執行 CaptureFullScreen 取得截圖
2. 執行 AnnotateScreenshot:
   - imagePath: 剛才的截圖路徑
   - annotationType: "circle"  
   - x: 500, y: 300
   - color: "red"
   - text: "重要功能"
```

### 範例 3: 批次作業
```
1. 執行 GetAllWindows 查看可用視窗
2. 執行 BatchCaptureWindows，windowTitles = "Chrome,記事本,VS Code"
```

### 範例 4: 分析和比較
```
1. 執行兩次 CaptureFullScreen 取得兩張截圖
2. 執行 CompareScreenshots 比較兩張圖片
3. 執行 AnalyzeScreenshot 分析圖片內容
```

## 檔案儲存位置
- 預設儲存路徑: `Desktop\Screenshots\`
- 標註後的圖片會新增 `_annotated` 後綴
- 縮圖會新增 `_thumbnail` 後綴
- 檔案格式: PNG

## 支援的標記顏色
- red (紅色)
- blue (藍色) 
- green (綠色)
- yellow (黃色)
- black (黑色)
- white (白色)
- orange (橘色)
- purple (紫色)

## 技術特色
- 🚀 基於 .NET 8.0 Windows 平台
- 🎯 整合 PowerShell 截圖自動化腳本
- 🔧 支援 MCP (Model Context Protocol) 標準
- 🎨 內建圖片處理和標註功能
- 📊 提供圖片分析和比較功能
- 🔄 支援批次處理和定時任務

## 啟動伺服器
```bash
cd MyMcpServer
dotnet run
```

## 注意事項
1. 本伺服器僅支援 Windows 平台
2. 需要 .NET 8.0 運行時環境
3. 部分功能需要管理員權限
4. 截圖功能會受到視窗最小化狀態影響
5. 大量截圖可能影響系統效能

## 整合 PowerShell 腳本
伺服器會自動呼叫 `Support\PowerShell_Screenshot_Automation.ps1` 腳本中的功能，提供更完整的截圖自動化能力。

---
*建立日期: 2025年6月15日*  
*版本: 1.0*  
*作者: MCP 螢幕截圖伺服器*
