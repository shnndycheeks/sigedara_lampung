import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final supabase = Supabase.instance.client;

  // ================= INIT =================
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    await _requestPermission();

    // START REALTIME LISTENER
    listenPeminjamanRealtime();
  }

  // ================= IZIN =================
  static Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ================= SHOW NOTIFICATION =================
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails =
        AndroidNotificationDetails(
      'sigedara_channel',
      'SIGEDARA Notification',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  // ================= REALTIME SUPABASE =================
  static void listenPeminjamanRealtime() {
    supabase
        .channel('peminjaman-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            final data = payload.newRecord;

            final status =
                data['status']?.toString() ?? '';

            final keperluan =
                data['keperluan']?.toString() ??
                    'Peminjaman';

            // ================= PENDING =================
            if (status == 'pending') {
              await showNotification(
                title: 'Pengajuan Baru',
                body:
                    'Ada pengajuan baru:\n$keperluan',
              );
            }

            // ================= DISETUJUI =================
            else if (status == 'disetujui') {
              await showNotification(
                title: 'Peminjaman Disetujui',
                body:
                    'Pengajuan disetujui:\n$keperluan',
              );
            }

            // ================= DITOLAK =================
            else if (status == 'ditolak') {
              await showNotification(
                title: 'Peminjaman Ditolak',
                body:
                    'Pengajuan ditolak:\n$keperluan',
              );
            }
          },
        )
        .subscribe();
  }
}