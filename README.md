# BusyLight Buddy

Multiplatform Flutter app to control your DIY [BusyLight](https://github.com/igox/busylight) (ESP32 + MicroPython + Microdot).

Supports **iOS**, **ipadOS**, **Android**, **macOS**, and **Windows**.

---

## Downloads

[![Windows](https://img.shields.io/badge/Windows-Installer-0078D4?style=for-the-badge&logo=windows&logoColor=white)](downloads/BusyLight-Buddy-Installer.exe)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](downloads/org.igox.apps.android.busylight-buddy-release.apk)

---

## Screenshots (iOS)

<img src="doc/screenshots/ios-screenshot-main.png" width="300" alt="BusyLight Companion — main screen" /> <img src="doc/screenshots/ios-screenshot-config.png" width="300" alt="BusyLight Companion — settings" />

---

## Features

### Status control
- Quick status presets: Available (green), Away (yellow), Busy (red), On, Off
- Live color preview circle with glow effect, synced with current status
- Status label displayed below the preview circle

### Custom color presets
- Color picker
- **Save & Apply** — pick a color, name it, save as a reusable preset and apply to BusyLight
- **Apply only** — apply color without saving
- Custom preset chips displayed in a horizontal scrollable row
- Long press on a preset chip to **Edit** (color + name) or **Delete**
- Edit mode updates the preset locally without applying to the BusyLight

### Brightness
- Brightness slider (0–100%)

### Background polling
- Automatically pulls status + color from device at a configurable interval
- Silent updates — no loading screen interruption
- Configurable in Settings (default: every 5 seconds, can be disabled)

### Settings
- Device address (hostname or IP, e.g. `http://igox-busylight.local`)
- Polling interval slider (Off → 1 min)
- Start with session (macOS and Windows only) — launch automatically at login

### UX & feedback
- Loading spinner per button during API calls (no full-screen takeover)
- User-friendly error screen with collapsible technical details

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
flutter run -d windows      # Windows
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
│   │   ├── busylight_service.dart     # All REST API calls
│   │   └── autostart_service.dart     # Start with session (macOS + Windows)
│   ├── providers/
│   │   ├── busylight_provider.dart    # Status, color, brightness, polling, config
│   │   └── presets_provider.dart      # Custom color presets (CRUD + persistence)
│   ├── screens/
│   │   ├── home_screen.dart           # Main screen
│   │   └── settings_screen.dart       # Configuration screen
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

---

## Platform setup

### Android — build APK

Two helper scripts are available in the `android/` folder to build and rename the APK in one step — one for macOS/Linux, one for Windows.

**macOS / Linux:**
```bash
# Debug build (default)
./flutter-build-apk.sh

# Release build
./flutter-build-apk.sh release
```

**Windows (PowerShell):**
```powershell
# Debug build (default)
.\flutter-build-apk.ps1

# Release build
.\flutter-build-apk.ps1 release
```

Both scripts build the APK with `flutter build apk`, then rename the output from `app-<type>.apk` to `org.igox.apps.android.busylight-buddy-<type>.apk` (and its `.sha1` file if present) in `build/app/outputs/flutter-apk/`.

### Windows — build release

```bash
flutter build windows --release
```

### Windows — build installer

The repository includes an [Inno Setup](https://jrsoftware.org/isdl.php) configuration file at the root of the repo to package the app as a Windows installer.

1. Download and install [Inno Setup](https://jrsoftware.org/isdl.php)
2. Build the release app first:
   ```bash
   flutter build windows --release
   ```
3. Open `busylight-buddy-windows-installer-builder.iss` in Inno Setup Compiler and click **Compile**, or run from the command line:
   ```bash
   iscc busylight-buddy-windows-installer-builder.iss
   ```

This generates a standalone `.exe` installer in the `windows/installer/` folder.

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