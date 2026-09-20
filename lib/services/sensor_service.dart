import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SensorTriggerMode {
  disabled,
  proximity,
}

/// Hands-free boxing trigger using the phone proximity sensor.
///
/// Most Android proximity sensors report NEAR/FAR instead of an exact
/// distance. The service triggers only on a FAR -> NEAR transition and
/// ignores the first reading after enabling to avoid accidental starts.
class SensorService extends ChangeNotifier {
  static const _modeKey = 'sensor_trigger_mode';

  StreamSubscription<dynamic>? _proximitySubscription;

  SensorTriggerMode _mode = SensorTriggerMode.proximity;
  bool _isProximityNear = false;
  bool _hasInitialReading = false;
  DateTime _lastTrigger = DateTime.fromMillisecondsSinceEpoch(0);

  VoidCallback? onTrigger;

  SensorTriggerMode get mode => _mode;
  bool get isEnabled => _mode != SensorTriggerMode.disabled;
  bool get isProximityNear => _isProximityNear;

  String get modeLabel {
    switch (_mode) {
      case SensorTriggerMode.disabled:
        return 'Manual';
      case SensorTriggerMode.proximity:
        return 'Proximity';
    }
  }

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_modeKey);

      _mode = switch (saved) {
        'disabled' => SensorTriggerMode.disabled,
        'proximity' => SensorTriggerMode.proximity,
        _ => SensorTriggerMode.proximity,
      };

      if (_mode == SensorTriggerMode.proximity) {
        _listenProximity();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Unable to initialize sensor settings: $e');
    }
  }

  Future<void> setMode(SensorTriggerMode mode) async {
    await _stopListening();
    _mode = mode;
    _isProximityNear = false;
    _hasInitialReading = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.name);
    } catch (e) {
      debugPrint('Unable to save sensor mode: $e');
    }

    if (mode == SensorTriggerMode.proximity) {
      _listenProximity();
    }

    notifyListeners();
  }

  void _listenProximity() {
    try {
      _proximitySubscription = ProximitySensor.events.listen(
        (int event) {
          final isNear = event > 0;

          if (!_hasInitialReading) {
            _isProximityNear = isNear;
            _hasInitialReading = true;
            notifyListeners();
            return;
          }

          // Only FAR -> NEAR triggers an action. Holding the glove near the
          // sensor cannot repeatedly start/pause the timer.
          if (isNear && !_isProximityNear) {
            _trigger();
          }

          _isProximityNear = isNear;
          notifyListeners();
        },
        onError: (Object error) {
          debugPrint('Proximity sensor error: $error');
        },
      );
    } catch (e) {
      debugPrint('Unable to start proximity sensor: $e');
    }
  }

  void _trigger() {
    final now = DateTime.now();

    // Hardware sensors can produce very fast duplicate transitions.
    if (now.difference(_lastTrigger).inMilliseconds < 900) {
      return;
    }

    _lastTrigger = now;
    debugPrint('Proximity sensor trigger received');
    onTrigger?.call();
  }

  Future<void> _stopListening() async {
    await _proximitySubscription?.cancel();
    _proximitySubscription = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
