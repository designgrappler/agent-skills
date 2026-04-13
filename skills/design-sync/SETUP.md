# Setting up Google Stitch MCP

To enable your Intelligence OS to "see" your designs, you must register the Stitch MCP server in your local environment.

## 1. Prerequisites
- Access to [stitch.withgoogle.com](https://stitch.withgoogle.com/).
- An MCP-compatible host (e.g., Cursor, Claude Desktop, or Antigravity).

## 2. Registration Command
Add the following configuration to your MCP settings file (e.g., `claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "stitch": {
      "command": "npx",
      "args": [
        "-y",
        "@google/stitch-mcp"
      ],
      "env": {
        "STITCH_API_KEY": "YOUR_API_KEY_HERE"
      }
    }
  }
}
```

## 3. Capabilities
Once registered, your agent will have access to:
- `list_projects`: See your available Stitch designs.
- `list_screens`: View the visual components of a specific project.
- `get_screen_details`: Fetch raw HTML/CSS and screenshots for coding.

> [!TIP]
> Use the **Design Sync Skill** (integrated into the dashboard) to automate the verification of these designs against your code.
