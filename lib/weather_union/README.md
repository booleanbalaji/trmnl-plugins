# Weather Union (TRMNL plugin)

Live, hyper-local weather for Indian cities using [Weather Union](https://www.weatherunion.com/) — a Zomato giveback with 600+ ground stations.

## What it shows

- Current temperature (°C / °F)
- Humidity
- Wind speed + cardinal direction
- Rain intensity (mm/min)
- Rain accumulation since midnight IST
- Nearest locality label (from the official station list)
- Station type: Automated Weather Station (AWS) or rain gauge

## Setup

1. Create a free API key at [weatherunion.com](https://www.weatherunion.com/) → profile → **Your API access key**.
2. Add this plugin and paste the key into **Weather Union API Key**.
3. Set your location with one of:
   - **Latitude / Longitude** — comma-separated, e.g. `28.630630, 77.220640` (Connaught Place). The API resolves the nearest station within ~2 km.
   - **Locality ID** — a `ZWLxxxxxx` station id (overrides lat/lon). Full list: [locality PDF](https://b.zmtcdn.com/data/file_assets/65fa362da3aa560a92f0b8aeec0dfda31713163042.pdf).

Optional: custom **Location label** and **Units** (metric / imperial).

## API reference

- Docs: [Weather Union API PDF](https://b.zmtcdn.com/data/file_assets/915d4e8e95d067c47e1ae38d77d572b21715104204.pdf)
- Dashboard: [get_weather_data](https://www.weatherunion.com/dashboard/#tag/default/GET/get_weather_data)
- Base URL: `https://www.weatherunion.com/gw/weather/external/v0`
- Auth header: `x-zomato-api-key`
- Endpoints used:
  - `GET /get_weather_data?latitude=&longitude=`
  - `GET /get_locality_weather_data?locality_id=`

## Coverage note

Weather Union only covers instrumented localities in India. Coordinates outside the network return a “not supported” response; pick a listed locality or a lat/lon near one of the stations in `data/localities.json`.

## Layouts

| Layout | Content |
| --- | --- |
| Full | Temperature hero + humidity, wind, rain intensity, today’s rain, station meta |
| Half vertical | Compact metrics grid |
| Half horizontal | Temperature + humidity/rain |
| Quadrant | Temperature, humidity, rain today |

## Deploy to your device

See [DEPLOY.md](./DEPLOY.md) for TRMNL MCP, ZIP import, and `trmnlp push`.
Importable archive: [`weather-union-trmnl.zip`](./weather-union-trmnl.zip).
