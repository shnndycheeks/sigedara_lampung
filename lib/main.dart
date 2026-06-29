import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigedara_lampung/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // MENGATUR APLIKASI MENJADI FULL SCREEN
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const SplashScreen(),
    );
  }
}
