import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:light/light.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

enum SensorTriggerMode {
  disabled,
  proximity,
  light,
  both,
}

/// Handles hands-free start/pause triggers from the phone's
/// proximity and ambient-light sensors.
class SensorService extends ChangeNotifier {
  StreamSubscription<dynamic>? _proximitySubscription;
  StreamSubscription<int>? _lightSubscription;

  SensorTriggerMode _mode = SensorTriggerMode.disabled;
  double _lightThreshold = 10.0;
  bool _isProximityNear = false;
  bool _isLightCovered = false;
  DateTime _lastTrigger = DateTime.fromMillisecondsSinceEpoch(0);

  VoidCallback? onTrigger;

  SensorTriggerMode get mode => _mode;
  double get lightThreshold => _lightThreshold;
  bool get isEnabled => _mode != SensorTriggerMode.disabled;
  bool get isProximityNear => _isProximityNear;
  bool get isLightCovered => _isLightCovered;

  String get modeLabel {
    switch (_mode) {
      case SensorTriggerMode.disabled:
        return 'Manual';
      case SensorTriggerMode.proximity:
        return 'Proximity';
      case SensorTriggerMode.light:
        return 'Light';
      case SensorTriggerMode.both:
        return 'Proximity + Light';
    }
  }

  Future<void> setMode(SensorTriggerMode mode) async {
    await _stopListening();
    _mode = mode;
    _isProximityNear = false;
    _isLightCovered = false;

    if (mode == SensorTriggerMode.proximity ||
        mode == SensorTriggerMode.both) {
      _listenProximity();
    }

    if (mode == SensorTriggerMode.light ||
        mode == SensorTriggerMode.both) {
      _listenLight();
    }

    notifyListeners();
  }

  void setLightThreshold(double value) {
    _lightThreshold = value.clamp(1.0, 200.0);
    notifyListeners();
  }

  void _listenProximity() {
    try {
      _proximitySubscription = ProximitySensor.events.listen(
        (int event) {
          final isNear = event > 0;

          // Trigger only when the sensor changes from FAR -> NEAR.
          // This prevents repeated triggers while the hand stays there.
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

  void _listenLight() {
    try {
      _lightSubscription = Light().lightSensorStream.listen(
        (int lux) {
          final isCovered = lux <= _lightThreshold;

          // Cover the light sensor to trigger once. It must be uncovered
          // before another trigger can happen.
          if (isCovered && !_isLightCovered) {
            _trigger();
          }

          _isLightCovered = isCovered;
          notifyListeners();
        },
        onError: (Object error) {
          debugPrint('Light sensor error: $error');
        },
      );
    } catch (e) {
      debugPrint('Unable to start light sensor: $e');
    }
  }

  void _trigger() {
    final now = DateTime.now();

    // Protect against duplicate events from both sensors or noisy hardware.
    if (now.difference(_lastTrigger).inMilliseconds < 900) {
      return;
    }

    _lastTrigger = now;
    debugPrint('Sensor trigger received');
    onTrigger?.call();
  }

  Future<void> _stopListening() async {
    await _proximitySubscription?.cancel();
    await _lightSubscription?.cancel();
    _proximitySubscription = null;
    _lightSubscription = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
