import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'studio/studio_controller.dart';
import 'studio/studio_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EqualizerPro());
}

class EqualizerPro extends StatelessWidget {
  const EqualizerPro({super.key, this.audioEnabled = true});

  final bool audioEnabled;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudioController(audioEnabled: audioEnabled)..initialize(),
      child: MaterialApp(
        title: 'Equalizer Pro',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          fontFamily: 'Segoe UI',
          scaffoldBackgroundColor: const Color(0xFF080B11),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC8FF3D),
            secondary: Color(0xFF5FE7FF),
            surface: Color(0xFF111720),
            error: Color(0xFFFF6B6B),
          ),
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.4,
              height: 1.05,
            ),
            headlineSmall: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            bodyMedium: TextStyle(fontSize: 14, height: 1.45),
            labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          sliderTheme: const SliderThemeData(
            activeTrackColor: Color(0xFFC8FF3D),
            inactiveTrackColor: Color(0xFF2B333F),
            thumbColor: Color(0xFFF7FFE2),
            overlayColor: Color(0x22C8FF3D),
            trackHeight: 3,
          ),
          tooltipTheme: TooltipThemeData(
            decoration: BoxDecoration(
              color: const Color(0xFF202833),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        home: const StudioShell(),
      ),
    );
  }
}
