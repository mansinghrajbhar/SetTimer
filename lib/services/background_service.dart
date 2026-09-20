import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class BackgroundService {
  bool _isBackgroundModeEnabled = false;

  Future<void> enableBackgroundMode() async {
    try {
      // Full-screen training mode: hide status/navigation bars while the
      // workout is actively running. Android can still restore them when
      // the user exits immersive mode.
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );

      _isBackgroundModeEnabled = true;
      developer.log(
        'Training mode enabled - immersive UI activated',
        name: 'BackgroundService',
      );
    } catch (e) {
      developer.log(
        'Failed to enable training mode: $e',
        name: 'BackgroundService',
        level: 1000,
      );
    }
  }

  Future<void> disableBackgroundMode() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );

      // Do not hard-code light/dark system-bar icon colors here. The
      // Material app supplies the current theme through AnnotatedRegion.
      _isBackgroundModeEnabled = false;
      developer.log(
        'Training mode disabled - normal system UI restored',
        name: 'BackgroundService',
      );
    } catch (e) {
      developer.log(
        'Failed to disable training mode: $e',
        name: 'BackgroundService',
        level: 1000,
      );
    }
  }

  bool get isEnabled => _isBackgroundModeEnabled;
}
