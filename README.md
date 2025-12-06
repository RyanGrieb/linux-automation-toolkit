# Ryan's Script Collection

A personal collection of Bash and Python scripts used to automate tasks, monitor system health, and manage workflows on my Linux machine.

## 📂 Repository Structure

| Directory         | Description                                                                                                   |
| :---------------- | :------------------------------------------------------------------------------------------------------------ |
| **Archive/**      | Old or deprecated scripts that are no longer in active use.                                                   |
| **AutoShutdown/** | Automatically shuts down the laptop after 30 minutes of idle time on battery power to save energy.            |
| **BashWeather/**  | Sets a `WEATHERCHAR` environment variable with an emoji based on current weather (via OpenWeatherMap API).    |
| **Convert/**      | Tools for file format conversion.                                                                             |
| **Health/**       | Monitors system health including battery status, SMART disk health, USB devices, and temperatures.            |
| **OpenMinimize/** | Scripts to launch applications (like email or task managers) and immediately minimize them to the background. |
| **Temperature/**  | Automated screen color temperature adjustment based on time of day (similar to f.lux).                        |
| **Verify/**       | Utilities for file verification and data validation.                                                          |

## 🚀 Setup & Usage

### BashWeather Configuration

The scripts in `BashWeather` require an API key to function.

1. Get a free API key from [OpenWeatherMap](https://openweathermap.org/).
2. Export it in your shell environment (e.g., in `~/.bashrc`):
   ```bash
   export OPEN_WEATHER_API_KEY="your_api_key_here"
   ```
