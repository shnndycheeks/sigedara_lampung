import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'services/supabase_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // INIT SUPABASE
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // INIT NOTIFICATION
  await AppNotificationService.init();

  runApp(const GerCepMajuApp());
}

class GerCepMajuApp extends StatelessWidget {
  const GerCepMajuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDark,
      builder: (_, isDark, __) {
        return MaterialApp(
          title: 'SIGEDARA LAMPUNG',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          darkTheme: buildDarkAppTheme(),
          themeMode: isDark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}