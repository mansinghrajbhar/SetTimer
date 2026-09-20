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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Sensor Controls'),
        backgroundColor: const Color(0xFF0A0A0A),
      ),
      body: AnimatedBuilder(
        animation: widget.controller.sensorService,
        builder: (context, _) {
          final sensor = widget.controller.sensorService;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _infoCard(
                title: 'Hands-Free Boxing Mode',
                text:
                    'One proximity trigger starts or resumes the timer. '
                    'The next proximity trigger pauses it. Manual buttons still work.',
              ),
              const SizedBox(height: 20),
              const Text(
                'Trigger Mode',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<SensorTriggerMode>(
                value: sensor.mode,
                dropdownColor: const Color(0xFF1A1A1A),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: SensorTriggerMode.disabled,
                    child: Text('Manual only'),
                  ),
                  DropdownMenuItem(
                    value: SensorTriggerMode.proximity,
                    child: Text('Proximity sensor'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    sensor.setMode(mode);
                  }
                },
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      sensor.isEnabled ? Icons.sensors : Icons.sensors_off,
                      color: sensor.isEnabled
                          ? const Color(0xFF00D4AA)
                          : Colors.white54,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sensor.isEnabled
                            ? 'Sensor mode: undefined'
                            : 'Sensor control disabled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proximity mode is designed for hands-free boxing. '
                'Move the glove close to the phone\'s top/front proximity sensor '
                'to trigger once, then move it away before the next trigger. '
                'Most phones report NEAR/FAR rather than an exact distance, so '
                'a precise 2–5 cm range cannot be guaranteed.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4AA).withOpacity(0.14),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00D4AA).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.sensors_outlined,
            color: Color(0xFF00D4AA),
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
