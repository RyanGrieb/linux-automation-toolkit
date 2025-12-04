# BashWeather

## Description

Bash prompt weather indicator. Sets `WEATHERCHAR` with emoji from OpenWeatherMap API. Requires `OPEN_WEATHER_API_KEY`. Uses LAT/LON or auto-detects location.

## Usage

Add the following to your `~/.bashrc`:

```bash
export OPEN_WEATHER_API_KEY="your_key"
export LAT="29.4241"
export LON="-98.4936"
. ~/Scripts/BashWeather.sh
PS1="[\u@\h \W] $WEATHERCHAR  "
```

**Note:** The `LAT` and `LON` environment variables are required for this script to work.
