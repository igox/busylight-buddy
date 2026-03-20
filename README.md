# BusyLight Buddy

Multiplatform Flutter app to control your DIY [BusyLight](https://github.com/igox/busylight) (ESP32 + MicroPython + Microdot).

Supports **iOS**, **macOS**, and **Android**.

---

## Features

### Status control
- Quick status presets: Available (green), Away (yellow), Busy (red), On, Off
- Live color preview circle with glow effect, synced with current status
- Status label displayed below the preview circle

### Custom color presets
- Color picker (RGB mode only — Alpha and other modes hidden, unsupported by API)
- **Save & Apply** — pick a color, name it, save as a reusable preset and apply to device
- **Apply only** — apply color without saving
- Custom preset chips displayed in a horizontal scrollable row
- Overflow indicator: fade + arrow + `· +N more` counter when presets overflow
- Long press on a preset chip to **Edit** (color + name) or **Delete**
- Edit mode updates the preset locally without applying to the BusyLight
- Presets persisted locally via SharedPreferences

### Brightness
- Brightness slider (0–100%), sourced from `GET /api/color` response (no separate API call)

### Background polling
- Automatically pulls status + color from device at a configurable interval
- Silent updates — no loading screen interruption
- Configurable in Settings (default: every 5 seconds, can be disabled)

### Settings
- Device address (hostname or IP, e.g. `http://igox-busylight.local`)
- Polling interval slider (Off → 1 min)

### UX & feedback
- Loading spinner per button during API calls (no full-screen takeover)
- User-friendly error screen with collapsible technical details
- Settings gear icon accessible from error screen
- All section titles use sentence case with consistent bold style

---

## Getting started

```bash
flutter pub get
flutter run
```

### Run on specific platform

```bash
flutter run -d iphone       # iOS simulator
open -a Simulator           # open iOS simulator first if needed
flutter run -d macos        # macOS
flutter run -d android      # Android emulator
```

---

## Project structure

```
busylight_app/
├── assets/
│   └── icon.png                       # App icon (all platforms)
├── lib/
│   ├── main.dart                      # App entry point
│   ├── models/
│   │   ├── busylight_status.dart      # Status enum + API paths
│   │   ├── busylight_color.dart       # Color model (r/g/b/brightness)
│   │   └── color_preset.dart          # Named color preset model
│   ├── services/
│   │   └── busylight_service.dart     # All REST API calls
│   ├── providers/
│   │   ├── busylight_provider.dart    # Status, color, brightness, polling, config
│   │   └── presets_provider.dart      # Custom color presets (CRUD + persistence)
│   ├── screens/
│   │   ├── home_screen.dart           # Main screen
│   │   └── settings_screen.dart      # Device address + polling interval
│   └── widgets/
│       ├── status_button.dart         # Animated status button with pending spinner
│       └── brightness_slider.dart     # Brightness control slider
└── pubspec.yaml
```

---

## API endpoints used

| Endpoint | Method | Description |
|---|---|---|
| `/api/status` | GET | Get current status |
| `/api/status/available` | POST/GET | Set available (green) |
| `/api/status/away` | POST/GET | Set away (yellow) |
| `/api/status/busy` | POST/GET | Set busy (red) |
| `/api/status/on` | POST/GET | Turn on (white) |
| `/api/status/off` | POST/GET | Turn off |
| `/api/color` | GET | Get current color + brightness |
| `/api/color` | POST | Set custom color (r, g, b, brightness) |
| `/api/brightness` | POST | Set brightness |
| `/api/debug` | GET | Full device debug info |

> Note: `GET /api/color` returns `{ "colors": { r, g, b }, "brightness": 0.3 }` — brightness is read from this response, no separate `/api/brightness` GET call is made.

---

## Platform setup

### iOS — allow HTTP (non-HTTPS)

In `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

### macOS — allow outgoing network connections

In both `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

### macOS — window size

In `macos/Runner/Base.lproj/MainMenu.xib`, set initial window size to 420×820:
```xml
<rect key="contentRect" x="335" y="390" width="420" height="820"/>
<rect key="frame" x="0.0" y="0.0" width="420" height="820"/>
```

In `macos/Runner/MainFlutterWindow.swift`:
```swift
self.minSize = NSSize(width: 420, height: 820)
self.setContentSize(NSSize(width: 420, height: 820))
```

### App icon (all platforms)

Uses `flutter_launcher_icons`. Icon source: `assets/icon.png`.

```bash
dart run flutter_launcher_icons
```

---

## Default device address

`http://igox-busylight.local` — configurable in Settings.

---

## A note on AI & vibe coding

This app was built entirely through **vibe coding** — a collaborative session with [Claude](https://claude.ai) (Anthropic), where the architecture, features, bug fixes, and UI decisions were developed iteratively through natural conversation, without writing a single line of code manually.

The full Flutter project — models, providers, screens, widgets, platform config — was generated, debugged, and refined through back-and-forth dialogue, screenshot feedback, and incremental feature requests.

> "Vibe coding" is a term for AI-assisted development where you describe what you want, review the result, and iterate — focusing on product decisions rather than syntax.