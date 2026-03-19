import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/busylight_color.dart';
import '../models/busylight_status.dart';

class BusylightException implements Exception {
  final String message;
  const BusylightException(this.message);
  @override
  String toString() => 'BusylightException: $message';
}

class BusylightService {
  final String baseUrl;
  final Duration timeout;

  BusylightService({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 5),
  });

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _get(String path) async {
    try {
      final res = await http.get(_uri(path)).timeout(timeout);
      _checkStatus(res);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on BusylightException {
      rethrow;
    } catch (e) {
      throw BusylightException('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    try {
      final res = await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
      _checkStatus(res);
      return jsonDecode(res.body) as Map<String, dynamic>;
    } on BusylightException {
      rethrow;
    } catch (e) {
      throw BusylightException('Network error: $e');
    }
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw BusylightException('HTTP ${res.statusCode}: ${res.body}');
    }
  }

  // ── Status ──────────────────────────────────────────────────────────────────

  Future<BusylightStatus> getStatus() async {
    final json = await _get('/api/status');
    return BusylightStatus.fromString(json['status'] as String);
  }

  Future<BusylightStatus> setStatus(BusylightStatus status) async {
    final json = await _post(status.apiPath);
    return BusylightStatus.fromString(json['status'] as String);
  }

  Future<BusylightStatus> turnOn()        => setStatus(BusylightStatus.on);
  Future<BusylightStatus> turnOff()       => setStatus(BusylightStatus.off);
  Future<BusylightStatus> setAvailable()  => setStatus(BusylightStatus.available);
  Future<BusylightStatus> setAway()       => setStatus(BusylightStatus.away);
  Future<BusylightStatus> setBusy()       => setStatus(BusylightStatus.busy);

  // ── Color ───────────────────────────────────────────────────────────────────

  Future<BusylightColor> getColor() async {
    final json = await _get('/api/color');
    return BusylightColor.fromJson(json);
  }

  Future<void> setColor(BusylightColor color) async {
    await _post('/api/color', color.toJson());
  }

  // ── Brightness ──────────────────────────────────────────────────────────────

  Future<double> getBrightness() async {
    final json = await _get('/api/brightness');
    return (json['brightness'] as num).toDouble();
  }

  Future<void> setBrightness(double brightness) async {
    await _post('/api/brightness', {'brightness': brightness.clamp(0.0, 1.0)});
  }

  // ── Debug ───────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDebug() => _get('/api/debug');
}
