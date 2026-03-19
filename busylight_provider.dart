import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/busylight_color.dart';
import '../models/busylight_status.dart';
import '../services/busylight_service.dart';

// ── Device config ────────────────────────────────────────────────────────────

const _kHostKey = 'busylight_host';
const _kDefaultHost = 'http://igox-busylight.local';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final deviceHostProvider = StateProvider<String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).valueOrNull;
  return prefs?.getString(_kHostKey) ?? _kDefaultHost;
});

// ── Service ──────────────────────────────────────────────────────────────────

final busylightServiceProvider = Provider<BusylightService>((ref) {
  final host = ref.watch(deviceHostProvider);
  return BusylightService(baseUrl: host);
});

// ── State notifiers ──────────────────────────────────────────────────────────

class BusylightStateNotifier extends StateNotifier<AsyncValue<BusylightStatus>> {
  BusylightStateNotifier(this._service) : super(const AsyncValue.loading()) {
    refresh();
  }

  final BusylightService _service;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_service.getStatus);
  }

  Future<void> setStatus(BusylightStatus status) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.setStatus(status));
  }
}

final busylightStatusProvider =
    StateNotifierProvider<BusylightStateNotifier, AsyncValue<BusylightStatus>>(
  (ref) => BusylightStateNotifier(ref.watch(busylightServiceProvider)),
);

// ── Brightness ───────────────────────────────────────────────────────────────

class BrightnessNotifier extends StateNotifier<double> {
  BrightnessNotifier(this._service) : super(1.0) {
    _load();
  }
  final BusylightService _service;

  Future<void> _load() async {
    try {
      state = await _service.getBrightness();
    } catch (_) {}
  }

  Future<void> set(double value) async {
    state = value;
    await _service.setBrightness(value);
  }
}

final brightnessProvider = StateNotifierProvider<BrightnessNotifier, double>(
  (ref) => BrightnessNotifier(ref.watch(busylightServiceProvider)),
);

// ── Color ─────────────────────────────────────────────────────────────────────

class ColorNotifier extends StateNotifier<BusylightColor> {
  ColorNotifier(this._service) : super(BusylightColor.white) {
    _load();
  }
  final BusylightService _service;

  Future<void> _load() async {
    try {
      state = await _service.getColor();
    } catch (_) {}
  }

  Future<void> set(BusylightColor color) async {
    state = color;
    await _service.setColor(color);
  }
}

final colorProvider = StateNotifierProvider<ColorNotifier, BusylightColor>(
  (ref) => ColorNotifier(ref.watch(busylightServiceProvider)),
);
