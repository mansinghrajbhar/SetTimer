import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/timer_controller.dart';
import 'views/timer_view.dart';

enum AppThemeMode { system, light, dark }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('app_theme_mode');
  final themeMode = switch (savedTheme) {
    'light' => AppThemeMode.light,
    'dark' => AppThemeMode.dark,
    _ => AppThemeMode.system,
  };

  runApp(WorkoutSetTimerApp(initialThemeMode: themeMode));
}

class WorkoutSetTimerApp extends StatefulWidget {
  final AppThemeMode initialThemeMode;

  const WorkoutSetTimerApp({super.key, this.initialThemeMode = AppThemeMode.system});

  @override
  State<WorkoutSetTimerApp> createState() => _WorkoutSetTimerAppState();
}

class _WorkoutSetTimerAppState extends State<WorkoutSetTimerApp> {
  late AppThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _applySystemUi(_themeMode == AppThemeMode.light ? Brightness.light : Brightness.dark);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', mode.name);
    if (mode != AppThemeMode.system) {
      _applySystemUi(mode == AppThemeMode.light ? Brightness.light : Brightness.dark);
    }
  }

  void _applySystemUi(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isLight ? Colors.white : Colors.black,
        systemNavigationBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      ),
    );
  }

  ThemeData _buildTheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withOpacity(0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = TimerController();
        controller.initialize();
        return controller;
      },
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final lightScheme = lightDynamic ??
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF00BFA5),
                brightness: Brightness.light,
              );
          final darkScheme = darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: const Color(0xFF00BFA5),
                brightness: Brightness.dark,
              );

          return MaterialApp(
            title: 'SetTimer',
            theme: _buildTheme(lightScheme),
            darkTheme: _buildTheme(darkScheme),
            themeMode: _themeMode == AppThemeMode.light
                ? ThemeMode.light
                : _themeMode == AppThemeMode.dark
                    ? ThemeMode.dark
                    : ThemeMode.system,
            home: TimerView(
              currentThemeMode: _themeMode,
              onThemeModeChanged: setThemeMode,
            ),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              final brightness = Theme.of(context).brightness;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _applySystemUi(brightness);
              });
              return GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: child,
              );
            },
          );
        },
      ),
    );
  }
}
