# Deploy Weather Union to your TRMNL device

There are three ways to get this onto your device. **MCP is the best path for iterating with Cursor.**

## Option A — TRMNL MCP (recommended for Cursor)

TRMNL exposes a live MCP server that can write plugin settings + markup directly to your account.

### 1. Create a private plugin shell

1. Open [New Private Plugin](https://trmnl.com/plugin_settings/new?keyname=private_plugin)
2. Name it `Weather Union`, click **Save**
3. On the settings page (right side), generate an **MCP API Key**

Docs: [AI Agent / MCP](https://help.trmnl.com/en/articles/14130438-ai-agent)

### 2. Add TRMNL MCP to Cursor

Edit `~/.cursor/mcp.json` (global) or this project's `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "trmnl": {
      "url": "https://trmnl.com/mcp?api_key=YOUR_MCP_KEY_HERE",
      "type": "http"
    }
  }
}
```

Restart Cursor → Settings → Tools & MCP → confirm `trmnl` is green.

For this Cloud Agent environment, add the same MCP server in the environment’s MCP settings, then re-run the agent.

### 3. What I’ll do once MCP is connected

1. `IntegrationsWriteSettingsTool` / `write_settings` — set polling strategy + Weather Union URL
2. Ask you to paste `polling_headers` in the TRMNL UI (`x-zomato-api-key=…`) — MCP cannot write headers (auth-protected)
3. Set custom fields: `api_key`, `latitude`, `longitude`, `location_label`
4. `IntegrationsRefreshDataTool` — pull live Weather Union data
5. `MergeVariablesShowTool` — verify `locality_weather_data`
6. `MarkupsWriteTool` — push full / half / quadrant Liquid from `private_plugin/`
7. `MarkupsScreenshotTool` — verify e-ink layout
8. Add the plugin to your device playlist if it isn’t already

Endpoint confirmed live: `POST https://trmnl.com/mcp`

---

## Option B — Import ZIP (fastest, no Cursor)

1. Download / build `weather-union-trmnl.zip` from `private_plugin/`:

```bash
cd lib/weather_union/private_plugin
zip -j ../../../weather-union-trmnl.zip \
  settings.yml full.liquid half_horizontal.liquid half_vertical.liquid quadrant.liquid
```

2. Go to [Private Plugins](https://trmnl.com/plugin_settings?keyname=private_plugin) → **Import new**
3. Fill in your Weather Union API key + lat/lon
4. Force refresh, then add to your playlist

Import docs: [Importing private plugins](https://help.trmnl.com/en/articles/10542599-importing-and-exporting-private-plugins)

---

## Option C — `trmnlp push` (CLI)

Uses your **User API Key** from [trmnl.com/account](https://trmnl.com/account) (not the MCP key).

```bash
gem install trmnl_preview   # or: docker run -it trmnl/trmnlp
export TRMNL_API_KEY=your_user_api_key
# put settings + liquid under src/ in a trmnlp project, then:
trmnlp login
trmnlp push
```

See [usetrmnl/trmnlp](https://github.com/usetrmnl/trmnlp).

---

## Keys you’ll need

| Key | Where | Used for |
| --- | --- | --- |
| Weather Union API key | [weatherunion.com](https://www.weatherunion.com/) profile | `x-zomato-api-key` header when polling |
| TRMNL MCP API key | Private plugin settings (right side after Save) | Cursor MCP (`https://trmnl.com/mcp?api_key=…`) |
| TRMNL User API key | [trmnl.com/account](https://trmnl.com/account) | `trmnlp push` / CI |

## Location tip

Weather Union only works within ~2 km of a listed station. Example Connaught Place:

- latitude `28.630630`
- longitude `77.220640`
- locality id `ZWL006538`
