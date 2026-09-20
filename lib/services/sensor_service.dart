import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

enum SensorTriggerMode {
  disabled,
  proximity,
}

/// Handles the phone's proximity sensor for hands-free timer control.
///
/// On most Android phones the proximity sensor reports NEAR/FAR rather than
/// an exact distance. For boxing, place the glove close to the top/front
/// sensor area to trigger a single start/pause action.
class SensorService extends ChangeNotifier {
  StreamSubscription<dynamic>? _proximitySubscription;

  SensorTriggerMode _mode = SensorTriggerMode.disabled;
  bool _isProximityNear = false;
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

  Future<void> setMode(SensorTriggerMode mode) async {
    await _stopListening();
    _mode = mode;
    _isProximityNear = false;

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

          // Trigger only on FAR -> NEAR. Holding the glove near the sensor
          // therefore does not repeatedly start/pause the timer.
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

    // Ignore duplicate/noisy hardware events for a short cooldown.
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
