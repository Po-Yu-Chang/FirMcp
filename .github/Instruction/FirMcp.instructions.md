---
applyTo: '**'
---
/*
  Copilot Instruction: 
  1. 幫我自動建立一個 .NET 7 Console 專案，專案名稱為 MyMcpServer。
  2. 安裝 NuGet 套件 ModelContextProtocol（prerelease）與 Microsoft.Extensions.Hosting。
  3. 生成 Program.cs，內容如下：
     using Microsoft.Extensions.DependencyInjection;
     using Microsoft.Extensions.Hosting;
     using Microsoft.Extensions.Logging;
     using ModelContextProtocol.Server;
     using System.ComponentModel;

     var builder = Host.CreateApplicationBuilder(args);
     builder.Logging.AddConsole(options => {
         options.LogToStandardErrorThreshold = LogLevel.Trace;
     });

     builder.Services
         .AddMcpServer()
         .WithStdioServerTransport()
         .WithToolsFromAssembly();

     await builder.Build().RunAsync();

  4. 在專案目錄下，建立一個檔案 LeaveRequestTool.cs，並產生以下內容：
     using ModelContextProtocol.Server;
     using System.ComponentModel;

     [McpServerToolType]
     public static class LeaveRequestTool
     {
         [McpServerTool, Description("取得請假天數")]
         public static int GetLeaveRecordAmount([Description("要查詢請假天數的員工名稱")] string employeeName)
         {
             if (employeeName.ToLower() == "david")
                 return 5;
             else if (employeeName.ToLower() == "eric")
                 return 8;
             else
                 return 3;
         }

         [McpServerTool, Description("進行請假，回傳結果")]
         public static string LeaveRequest(
             [Description("請假起始日期")] string 請假起始日期,
             [Description("請假天數")] int 天數,
             [Description("請假事由")] string 請假事由,
             [Description("代理人")] string 代理人,
             [Description("請假者姓名")] string 請假者姓名)
         {
             if (string.IsNullOrEmpty(請假起始日期) ||
                 string.IsNullOrEmpty(請假事由) ||
                 string.IsNullOrEmpty(代理人) ||
                 string.IsNullOrEmpty(請假者姓名))
             {
                 return "請假失敗，請確認所有必填欄位已填寫。";
             }
             var result = $"{請假者姓名} 請假 {天數} 天，從 {請假起始日期} 開始，事由為 {請假事由}，代理人 {代理人}";
             return result;
         }

         [McpServerTool, Description("取得今天日期")]
         public static string GetCurrentDate()
         {
             return DateTime.UtcNow.AddHours(8).ToString("yyyy-MM-dd HH:mm:ss");
         }
     }

  5. 在專案根目錄下，建立資料夾 .vscode，並在其中新增 mcp.json，內容如下：
     {
       "servers": {
         "MyMcpServer": {
           "type": "stdio",
           "command": "dotnet",
           "args": [
             "run",
             "--project",
             "${workspaceFolder}/MyMcpServer.csproj"
           ]
         }
       }
     }

  6. 最後確認專案可以直接用 `dotnet run` 運行，並能夠偵測到上述三個工具函式（GetLeaveRecordAmount、LeaveRequest、GetCurrentDate）。

  請 Copilot 幫我一次生成所有檔案（MyMcpServer.csproj、Program.cs、LeaveRequestTool.cs、.vscode/mcp.json）與所需目錄結構。
*/ 
