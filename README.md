# SQL MCP Server — Connect Copilot Studio to Azure SQL

Connect a Microsoft Copilot Studio agent to an Azure SQL Database using [SQL MCP Server](https://learn.microsoft.com/en-us/azure/data-api-builder/mcp/overview) (Data API builder). No custom APIs, no Power Automate flows, no connector code.

## What This Does

SQL MCP Server turns your database tables into MCP tools that AI agents can discover and call. The agent queries your data using structured tools — not raw SQL. Data API builder generates the actual T-SQL deterministically behind the scenes.

**Architecture:**

```
User → Copilot Studio Agent → MCP Endpoint (HTTPS) → Data API Builder → Azure SQL Database
```

## Quick Start

### Prerequisites

- [.NET 8 SDK](https://dotnet.microsoft.com/download) or later
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure subscription
- An Azure SQL Database with tables
- Access to [Copilot Studio](https://copilotstudio.microsoft.com)

### 1. Clone and install

```bash
git clone https://github.com/rafsan-huseynov/sql-mcp-server.git
cd sql-mcp-server
dotnet tool restore
```

### 2. Configure your connection

Create a `.env` file in the project root:

```
MSSQL_CONNECTION_STRING="Server=<your-server>.database.windows.net;Database=<your-database>;User Id=<your-username>;Password=<your-password>;TrustServerCertificate=True"
```

> **Important:** The connection string must be on a single line wrapped in double quotes.

### 3. Add your tables

```bash
dotnet dab add <EntityName> --source dbo.<TableName> --permissions "anonymous:read" --description "<plain English description>"
```

Example:

```bash
dotnet dab add Customers --source dbo.Customers --permissions "anonymous:read" --description "Customer records including names, emails, account status, regions, and annual premiums"
```

### 4. Test locally

```bash
dotnet dab start
```

In a separate terminal:

```bash
curl http://localhost:5000/api/<EntityName>
```

### 5. Deploy to Azure

```bash
az acr login --name <registry-name>
docker build --platform linux/amd64 -t <registry-name>.azurecr.io/sql-mcp-server:v1 .
docker push <registry-name>.azurecr.io/sql-mcp-server:v1
```

```bash
az containerapp up --name sql-mcp-server --resource-group <your-rg> --image <registry-name>.azurecr.io/sql-mcp-server:v1 --registry-server <registry-name>.azurecr.io --ingress external --target-port 5000 --env-vars "MSSQL_CONNECTION_STRING=<your-connection-string>"
```

### 6. Connect to Copilot Studio

1. Open [copilotstudio.microsoft.com](https://copilotstudio.microsoft.com)
2. Go to **Tools** → **Add a tool** → **New tool** → **Model Context Protocol**
3. Enter your MCP endpoint: `https://<your-app-url>/mcp`
4. Select **No authentication**
5. Create a connection and test

## Project Structure

```
sql-mcp-server/
├── .env                  # Connection string (not committed)
├── .gitignore            # Excludes .env from Git
├── dab-config.json       # DAB configuration (tables, permissions, MCP settings)
├── Dockerfile            # Container image definition
└── dotnet-tools.json     # .NET tool manifest (DAB CLI)
```

## Key Files

| File | Purpose |
|------|---------|
| `dab-config.json` | Defines which tables to expose, permissions, and MCP endpoint settings |
| `Dockerfile` | Packages DAB + config into a container for Azure deployment |
| `.env` | Stores the database connection string locally (never committed) |

## Common Issues

| Error | Fix |
|-------|-----|
| `.env` parsing error ("unexpected 'U'") | Connection string must be one line, wrapped in double quotes |
| "command not found: dab" | Use `dotnet dab` instead of `dab` |
| Container crashes with .NET 8 missing | Use `sdk:8.0` in Dockerfile, not `sdk:9.0` |
| "Dockerfile not found" | File must be named exactly `Dockerfile` (capital D) |
| Docker socket error | Open Docker Desktop first |
| Copilot Studio shows no tools | Wait 30 seconds for tool sync, ensure container is running |

## MCP Tools (Auto-Generated)

DAB automatically creates these tools from your config:

| Tool | Description |
|------|-------------|
| `describe_entities` | Discover available tables and columns |
| `read_records` | Query data with filters |
| `aggregate_records` | Count, sum, average |
| `create_record` | Insert a row |
| `update_record` | Update a row |
| `delete_record` | Delete a row |
| `execute_entity` | Run a stored procedure |

## Production Considerations

This repo is configured for development/demo use. For production:

- **Authentication:** Add Entra ID JWT validation on the MCP endpoint
- **Secrets:** Store connection string in Azure Key Vault using `@akv()`
- **Database auth:** Use Managed Identity instead of username/password
- **Host mode:** Change to `"mode": "production"` in `dab-config.json`
- **Network:** Add VNet integration between Container Apps and Azure SQL
- **Permissions:** Replace `anonymous:read` with named roles
- **Monitoring:** Connect Application Insights for telemetry

## Resources

- [SQL MCP Server Overview](https://learn.microsoft.com/en-us/azure/data-api-builder/mcp/overview)
- [VS Code Quickstart](https://learn.microsoft.com/en-us/azure/data-api-builder/mcp/quickstart-visual-studio-code)
- [Connect MCP to Copilot Studio](https://learn.microsoft.com/en-us/microsoft-copilot-studio/mcp-add-existing-server-to-agent)
- [DAB CLI Reference](https://learn.microsoft.com/en-us/azure/data-api-builder/command-line)
- [Azure Container Apps Deployment](https://learn.microsoft.com/en-us/azure/data-api-builder/mcp/quickstart-azure-container-apps)

## Video Walkthrough

📺 [Watch the full tutorial on YouTube](https://youtube.com/@rafsanhuseynov)

## Author

**Rafsan Huseynov** — AI Solutions Architect | Microsoft MVP (Copilot Studio & Microsoft Foundry)

- [YouTube](https://youtube.com/@rafsanhuseynov)
- [LinkedIn](https://linkedin.com/in/rafsanhuseynov)
- [GitHub](https://github.com/rafsan-huseynov)

## License

MIT