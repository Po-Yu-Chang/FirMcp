# FirMcp

This project is a .NET 7 console application that functions as an MCP (Model Context Protocol) server. It includes sample tools for demonstration purposes.

## MyMcpServer

The `MyMcpServer` is the main application within this project. It demonstrates how to set up an MCP server and define tools that can be invoked by an MCP client.

### Features

* MCP server implementation using `ModelContextProtocol`.
* Sample tools defined in `LeaveRequestTool.cs`:
  * `GetLeaveRecordAmount`: Retrieves the amount of leave records.
  * `LeaveRequest`: Submits a leave request.
  * `GetCurrentDate`: Gets the current date.

### Getting Started

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Po-Yu-Chang/FirMcp.git
   cd FirMcp
   ```

2. **Run the server:**

   The server is configured to run via stdio when launched through the `.vscode/mcp.json` configuration (see below).
   Alternatively, you can run the project directly:

   ```bash
   dotnet run --project MyMcpServer/MyMcpServer.csproj
   ```

### MCP Configuration (`.vscode/mcp.json`)

This file configures how VS Code interacts with the MCP server. The current configuration specifies that the server (`MyMcpServer`) communicates via standard input/output (stdio) and is launched by running the `MyMcpServer.csproj` project.

```json
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
```

### Project Structure

* `FirMcp.sln`: Visual Studio solution file.
* `MyMcpServer/`: Contains the .NET 7 console application.
  * `Program.cs`: Main entry point, sets up and runs the MCP server.
  * `LeaveRequestTool.cs`: Defines sample MCP tools.
  * `MyMcpServer.csproj`: Project file for the server application.
* `.vscode/`: Contains VS Code specific configurations.
  * `mcp.json`: Configuration for the MCP server.
* `.gitignore`: Specifies intentionally untracked files that Git should ignore.
* `README.md`: This file.
