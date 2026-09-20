import 'package:flutter/material.dart';
import '../controllers/timer_controller.dart';
import '../services/sensor_service.dart';

class SensorSettingsView extends StatefulWidget {
  final TimerController controller;

  const SensorSettingsView({super.key, required this.controller});

  @override
  State<SensorSettingsView> createState() => _SensorSettingsViewState();
}

class _SensorSettingsViewState extends State<SensorSettingsView> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proximity controls'),
      ),
      body: AnimatedBuilder(
        animation: widget.controller.sensorService,
        builder: (context, _) {
          final sensor = widget.controller.sensorService;

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Card(
                color: scheme.primaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        child: const Icon(Icons.sports_mma_rounded),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hands-free boxing',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Bring the glove close to the top/front proximity sensor to start or pause. Move away before the next trigger.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Trigger mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: BorderSide(color: scheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    RadioListTile<SensorTriggerMode>(
                      value: SensorTriggerMode.proximity,
                      groupValue: sensor.mode,
                      onChanged: (mode) {
                        if (mode != null) sensor.setMode(mode);
                      },
                      title: const Text('Proximity sensor'),
                      subtitle: const Text('Recommended for boxing'),
                      secondary: Icon(Icons.sensors_rounded, color: scheme.primary),
                    ),
                    RadioListTile<SensorTriggerMode>(
                      value: SensorTriggerMode.disabled,
                      groupValue: sensor.mode,
                      onChanged: (mode) {
                        if (mode != null) sensor.setMode(mode);
                      },
                      title: const Text('Manual only'),
                      subtitle: const Text('Use the on-screen controls'),
                      secondary: Icon(Icons.touch_app_outlined, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        sensor.isEnabled
                            ? (sensor.isProximityNear
                                ? Icons.near_me_rounded
                                : Icons.sensors_rounded)
                            : Icons.sensors_off_rounded,
                        color: sensor.isEnabled ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sensor.isEnabled
                                  ? sensor.modeLabel + ' mode active'
                                  : 'Sensor control disabled',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              sensor.isEnabled
                                  ? (sensor.isProximityNear
                                      ? 'Near detected'
                                      : 'Waiting for glove')
                                  : 'Manual buttons remain available',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'How it works',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              _step(context, '1', 'Move the glove near the phone sensor.', scheme.primary),
              _step(context, '2', 'FAR → NEAR starts or resumes the timer.', scheme.secondary),
              _step(context, '3', 'Move away, then NEAR again pauses the timer.', scheme.tertiary),
              const SizedBox(height: 8),
              Text(
                'Most Android phones expose a NEAR/FAR reading rather than an exact distance. A precise 2–5 cm trigger cannot be guaranteed on every device.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _step(BuildContext context, String number, String text, Color color) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withOpacity(0.14),
            foregroundColor: color,
            child: Text(number, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
