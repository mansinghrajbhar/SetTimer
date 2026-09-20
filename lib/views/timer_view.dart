
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/timer_controller.dart';
import '../models/timer_model.dart';
import '../services/achievement_service.dart';
import '../services/sensor_service.dart';
import '../widgets/save_template_dialog.dart';
import '../widgets/achievement_notification_widget.dart';
import 'preset_selection_view.dart';
import 'audio_settings_view.dart';
import 'voice_coaching_settings_view.dart';
import 'workout_history_view.dart';
import 'sensor_settings_view.dart';

class TimerView extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const TimerView({
    super.key,
    this.currentThemeMode = ThemeMode.system,
    required this.onThemeModeChanged,
  });

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  final AchievementService _achievementService = AchievementService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);

    _achievementService.achievementUnlocked.listen((achievement) {
      if (mounted) {
        AchievementNotificationOverlay.show(context, achievement);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Consumer<TimerController>(
        builder: (context, controller, _) {
          final timer = controller.timer;

          if (timer.state == TimerState.completed) {
            return _buildCompletionScreen(controller);
          }

          return SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildHeader(controller),
                      const SizedBox(height: 18),
                      _buildTimerCard(controller, timer),
                      const SizedBox(height: 16),
                      _buildRoundInfo(controller, timer),
                      const SizedBox(height: 18),
                      _buildPrimaryControls(controller, timer),
                      const SizedBox(height: 18),
                      _buildSensorCard(controller),
                      const SizedBox(height: 18),
                      _buildQuickTools(controller),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(TimerController controller) {
    final scheme = Theme.of(context).colorScheme;
    final sensor = controller.sensorService;
    final preset = controller.currentPresetName;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Boxing Timer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                preset ?? 'Train hard • stay on round',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildStatusPill(
          icon: sensor.isEnabled ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          label: sensor.isEnabled ? 'Glove' : 'Manual',
          color: sensor.isEnabled ? scheme.primary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'More',
          onPressed: () => _showQuickActionsMenu(context, controller),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerCard(TimerController controller, TimerModel timer) {
    final scheme = Theme.of(context).colorScheme;
    final isRest = timer.isInRestPeriod;
    final isRunning =
        timer.state == TimerState.running || timer.state == TimerState.resting;
    final accent = isRest ? scheme.tertiary : scheme.primary;
    final total = isRest ? timer.restDurationSeconds : timer.setDurationSeconds;
    final elapsed = total - timer.remainingSeconds;
    final progress = total <= 0 ? 0.0 : (elapsed / total).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          children: [
            Row(
              children: [
                _buildPhaseChip(
                  label: isRest ? 'REST' : 'ROUND',
                  color: accent,
                ),
                const Spacer(),
                Text(
                  isRunning
                      ? 'IN PROGRESS'
                      : timer.state == TimerState.paused
                          ? 'PAUSED'
                          : 'READY',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 248,
              height: 248,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 232,
                    height: 232,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 11,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final scale = isRunning
                          ? 1.0 + (_pulseController.value * 0.018)
                          : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(timer.remainingSeconds),
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 58,
                                letterSpacing: -2.5,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRest ? 'Recovery' : 'Work round',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              (progress * 100).round().toString() + '% complete',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 9, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundInfo(TimerController controller, TimerModel timer) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildInfoTile(
            icon: Icons.sports_mma_rounded,
            title: 'Round',
            value: timer.currentSet.toString() + ' / ' + timer.totalSets.toString(),
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.timer_outlined,
            title: 'Round time',
            value: _formatDuration(timer.setDurationSeconds),
            color: scheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildInfoTile(
            icon: Icons.pause_circle_outline_rounded,
            title: 'Rest',
            value: _formatDuration(timer.restDurationSeconds),
            color: scheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 13, 10, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryControls(TimerController controller, TimerModel timer) {
    final scheme = Theme.of(context).colorScheme;
    final isActive =
        timer.state == TimerState.running || timer.state == TimerState.resting;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: isActive ? controller.pauseTimer : controller.startTimer,
            icon: Icon(isActive ? Icons.pause_rounded : Icons.play_arrow_rounded),
            label: Text(
              isActive
                  ? 'Pause round'
                  : timer.state == TimerState.paused
                      ? 'Resume round'
                      : 'Start workout',
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              backgroundColor: isActive ? scheme.tertiary : scheme.primary,
              foregroundColor: isActive ? scheme.onTertiary : scheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filledTonal(
          tooltip: 'Reset',
          onPressed: timer.state == TimerState.idle ? null : controller.resetTimer,
          icon: const Icon(Icons.restart_alt_rounded),
          style: IconButton.styleFrom(
            minimumSize: const Size(58, 58),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(TimerController controller) {
    final scheme = Theme.of(context).colorScheme;
    final sensor = controller.sensorService;
    final enabled = sensor.isEnabled;
    final near = sensor.isProximityNear;

    return Card(
      margin: EdgeInsets.zero,
      color: enabled
          ? scheme.primaryContainer.withOpacity(0.72)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
        side: BorderSide(
          color: enabled
              ? scheme.primary.withOpacity(0.25)
              : scheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SensorSettingsView(controller: controller),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: enabled
                      ? scheme.primary.withOpacity(0.14)
                      : scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  enabled ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                  color: enabled ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      enabled ? 'Hands-free boxing' : 'Hands-free boxing is off',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      enabled
                          ? near
                              ? 'Glove detected • move away for the next trigger'
                              : 'Move glove near the top sensor to start/pause'
                          : 'Enable proximity control for glove-triggered start/pause',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickTools(TimerController controller) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _buildToolButton(
            icon: Icons.library_books_outlined,
            label: 'Presets',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PresetSelectionView()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToolButton(
            icon: Icons.history_rounded,
            label: 'History',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkoutHistoryView()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToolButton(
            icon: Icons.volume_up_outlined,
            label: 'Sounds',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AudioSettingsView()),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildToolButton(
            icon: Icons.tune_rounded,
            label: 'Settings',
            onTap: () => _showSettingsModal(context, controller),
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.45)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary, size: 23),
              const SizedBox(height: 7),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionScreen(TimerController controller) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 108,
                height: 108,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Workout complete',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Great work. Your rounds are saved locally.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: controller.resetTimer,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start another workout'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutHistoryView()),
                ),
                icon: const Icon(Icons.history_rounded),
                label: const Text('View history'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context, TimerController controller) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _SettingsModal(controller: controller),
    );
  }

  void _showQuickActionsMenu(BuildContext context, TimerController controller) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: scheme.surface,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Training controls',
                    style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Everything you need for a hands-free boxing session.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSheetAction(
                  context: sheetContext,
                  icon: Icons.auto_awesome_rounded,
                  title: 'Appearance',
                  subtitle: 'Dynamic, light or dark',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showThemePicker();
                  },
                ),
                _buildSheetAction(
                  context: sheetContext,
                  icon: Icons.sensors_rounded,
                  title: 'Proximity controls',
                  subtitle: 'Glove start / pause',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SensorSettingsView(controller: controller),
                      ),
                    );
                  },
                ),
                _buildSheetAction(
                  context: sheetContext,
                  icon: Icons.record_voice_over_outlined,
                  title: 'Voice coaching',
                  subtitle: 'Round and countdown announcements',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VoiceCoachingSettingsView(),
                      ),
                    );
                  },
                ),
                _buildSheetAction(
                  context: sheetContext,
                  icon: Icons.bookmark_add_outlined,
                  title: 'Save template',
                  subtitle: 'Save this workout as a preset',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showSaveTemplateDialog(controller);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetAction({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) {
        final scheme = Theme.of(sheetContext).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Appearance',
                style: Theme.of(sheetContext).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use Android wallpaper colors or choose a fixed theme.',
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              _buildThemeChoice(
                context: sheetContext,
                mode: ThemeMode.system,
                icon: Icons.auto_awesome_rounded,
                title: 'Dynamic / System',
                subtitle: 'Follow Android Material You',
              ),
              _buildThemeChoice(
                context: sheetContext,
                mode: ThemeMode.light,
                icon: Icons.light_mode_outlined,
                title: 'Light',
                subtitle: 'Clean bright training UI',
              ),
              _buildThemeChoice(
                context: sheetContext,
                mode: ThemeMode.dark,
                icon: Icons.dark_mode_outlined,
                title: 'Dark',
                subtitle: 'Low-light training UI',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeChoice({
    required BuildContext context,
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = widget.currentThemeMode == mode;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant.withOpacity(0.45),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: selected ? scheme.primary : scheme.surfaceContainerHighest,
          foregroundColor: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          child: Icon(icon),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onTap: () {
          widget.onThemeModeChanged(mode);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSaveTemplateDialog(TimerController controller) {
    showDialog(
      context: context,
      builder: (context) => SaveTemplateDialog(
        currentSettings: controller.getCurrentSettingsAsPreset(
          name: '',
          description: '',
        ),
        onSaved: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Template saved successfully'),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        },
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return minutes.toString().padLeft(2, '0') +
        ':' +
        remainingSeconds.toString().padLeft(2, '0');
  }

  String _formatDuration(int seconds) {
    if (seconds % 60 == 0) {
      return (seconds ~/ 60).toString() + 'm';
    }
    return (seconds ~/ 60).toString() + 'm ' + (seconds % 60).toString() + 's';
  }
}
class _SettingsModal extends StatefulWidget {
  final TimerController controller;

  const _SettingsModal({required this.controller});

  @override
  State<_SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<_SettingsModal> {
  late int _totalSets;
  late int _setDuration;
  late int _restDuration;
  late int _restAfterSets;

  @override
  void initState() {
    super.initState();
    final timer = widget.controller.timer;
    _totalSets = timer.totalSets;
    _setDuration = timer.setDurationSeconds;
    _restDuration = timer.restDurationSeconds;
    _restAfterSets = timer.restAfterSets;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Timer Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 30),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSlider('Total Sets', _totalSets, 1, 20, (value) {
                    setState(() => _totalSets = value.round());
                  }, context),
                  _buildSlider('Set Duration (seconds)', _setDuration, 10, 300, (value) {
                    setState(() => _setDuration = value.round());
                  }, context),
                  _buildSlider('Rest Duration (seconds)', _restDuration, 5, 120, (value) {
                    setState(() => _restDuration = value.round());
                  }, context),
                  _buildSlider('Rest After Sets', _restAfterSets, 1, 5, (value) {
                    setState(() => _restAfterSets = value.round());
                  }, context),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white30,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    widget.controller.updateTimerSettings(
                      totalSets: _totalSets,
                      setDurationSeconds: _setDuration,
                      restDurationSeconds: _restDuration,
                      restAfterSets: _restAfterSets,
                    );
                    Navigator.pop(context);

                    // Show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings updated successfully!'),
                        backgroundColor: Color(0xFF00D4AA),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4AA),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, int value, int min, int max, ValueChanged<double> onChanged, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: Color(0xFF00D4AA),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00D4AA),
              inactiveTrackColor: Colors.white.withOpacity(0.2),
              thumbColor: const Color(0xFF00D4AA),
              overlayColor: const Color(0xFF00D4AA).withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
