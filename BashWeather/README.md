# BashWeather

A lightweight Bash prompt integration that displays the current weather as an emoji. It fetches weather data from the OpenWeatherMap API and caches it to minimize network requests.

## Features

- **Emoji Weather**: Shows sunny, cloudy, rainy, snowy, etc., as emojis.
- **Smart Caching**: Updates weather only every 3 hours (configurable) to avoid hitting API limits.
- **Async-ish**: Can be run in `PS1` without significant lag (if configured correctly with caching).
- **Location Aware**: Uses fixed coordinates or IP-based location.

## Prerequisites

- `curl` (for API requests)
- `grep`, `sed` (standard coreutils)
- An API Key from [OpenWeatherMap](https://openweathermap.org/) (Free tier is sufficient).

## Installation

1. **Copy the script**: Place `BashWeather.sh` in a convenient location, e.g., `~/Scripts/BashWeather/`.
2. **Configure Environment Variables**:
   Add the following to your `~/.bashrc` (or `~/.zshrc`):

   ```bash
   # OpenWeatherMap API Key
   export OPEN_WEATHER_API_KEY="your_api_key_here"

   # Location (Latitude/Longitude)
   # You can find these on Google Maps or OpenWeatherMap
   export LAT="40.7128"
   export LON="-74.0060"
   ```

3. **Source the Script**:
   Add this to your shell config file *after* the exports:

   ```bash
   # Source the weather script
   . ~/Scripts/BashWeather/BashWeather.sh

   # Add to your prompt (PS1)
   # \u = user, \h = host, \W = current dir
   PS1="[\u@\h \W] \$WEATHERCHAR $ "
   ```

4. **Reload Shell**: `source ~/.bashrc` or restart your terminal.

## options & Advanced Usage

You can customize `BashWeather.sh` by passing flags when sourcing it, or by modifying the source command.

### Command Line Arguments

| Flag | Description | Default |
|------|-------------|---------|
| `-c <char>` | Default character if weather is unavailable. | `$` |
| `-l <loc>` | Location string (e.g., "London,UK") instead of Lat/Lon. | IP/Env |
| `-u <seconds>` | Update interval in seconds. | `10800` (3h) |
| `-s <string>` | String to append when weather was *just* updated. | None |
| `-t <seconds>` | HTTP timeout for API requests. | `1` |
| `-e` | Echo the emoji immediately (command mode) instead of setting variable. | Off |
| `-h` | Show help message. | - |

### Examples

**Aggressive Timeout (fast fail for laptops):**
```bash
. ~/Scripts/BashWeather/BashWeather.sh -t 1
```

**Custom Update Interval (every hour):**
```bash
. ~/Scripts/BashWeather/BashWeather.sh -u 3600
```

**Use as a standalone command:**
```bash
# Just print the weather emoji right now
~/Scripts/BashWeather/BashWeather.sh -e
```

## Troubleshooting

- **No Emoji?**: Check if `OPEN_WEATHER_API_KEY` is set and valid.
- **Wrong Location?**: Ensure `LAT` and `LON` are set correctly. If omitted, it tries to guess based on IP, which may be inaccurate.
- **Visual Glitches?**: Ensure your terminal font supports emojis.
