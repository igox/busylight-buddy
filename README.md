# BusyLight Flutter App

Multiplatform Flutter app to control your DIY [BusyLight](https://github.com/igox/busylight) (ESP32 + MicroPython + Microdot).

## Features

- Quick status presets: Available (green), Away (yellow), Busy (red), On/Off
- Custom color picker
- Brightness control
- Live color preview with glow effect
- Configurable device IP/hostname
- Error handling with retry

## Getting started

```bash
flutter pub get
flutter run
```

## Project structure

```
lib/
├── main.dart                      # App entry point + MaterialApp
├── models/
│   ├── busylight_status.dart      # Status enum + API paths
│   └── busylight_color.dart       # Color model (r/g/b/brightness)
├── services/
│   └── busylight_service.dart     # All REST API calls
├── providers/
│   └── busylight_provider.dart    # Riverpod state (status, color, brightness, config)
├── screens/
│   ├── home_screen.dart           # Main screen
│   └── settings_screen.dart      # IP/hostname config
└── widgets/
    ├── status_button.dart         # Animated status preset button
    └── brightness_slider.dart     # Brightness control
```

## API endpoints used

| Endpoint | Method | Description |
|---|---|---|
| `/api/status` | GET | Get current status |
| `/api/status/{name}` | POST | Set status preset |
| `/api/color` | GET/POST | Get/set custom color |
| `/api/brightness` | GET/POST | Get/set brightness |
| `/api/debug` | GET | Full debug info |

## Default device address

`http://igox-busylight.local` — configurable in Settings.
