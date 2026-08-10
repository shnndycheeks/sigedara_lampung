import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static final supabase = Supabase.instance.client;

  // ================= INIT =================
  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
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
    const androidDetails = AndroidNotificationDetails(
      'simaster_channel',
      'SIMASTER Notification',
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

  // ================= REALTIME SUPABASE PEMINJAMAN =================
  static void listenPeminjamanRealtime() {
    supabase
        .channel('peminjaman-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            final data = payload.newRecord;
            final status = data['status']?.toString() ?? '';
            final keperluan = data['keperluan']?.toString() ?? 'Peminjaman';

            if (status == 'pending') {
              await showNotification(
                title: 'Pengajuan Baru',
                body: 'Ada pengajuan baru:\n$keperluan',
              );
            } else if (status == 'disetujui') {
              await showNotification(
                title: 'Peminjaman Disetujui',
                body: 'Pengajuan disetujui:\n$keperluan',
              );
            } else if (status == 'ditolak') {
              await showNotification(
                title: 'Peminjaman Ditolak',
                body: 'Pengajuan ditolak:\n$keperluan',
              );
            }
          },
        )
        .subscribe();
  }

  // ================= METODE NOTIFIKASI DISPOSISI DATABASE =================

  /// Memuat notifikasi user dari tabel `notifications`
  static Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final listMap = List<Map<String, dynamic>>.from(data);
      return listMap.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[LOG ERR] Gagal memuat notifikasi ($userId): $e');
      throw Exception('Gagal memuat notifikasi: $e');
    }
  }

  /// Menandai notifikasi sebagai sudah dibaca
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await supabase.from('notifications').update({
        'is_read': true,
      }).eq('id', notificationId);
    } catch (e) {
      debugPrint('[LOG ERR] Gagal update status notifikasi ($notificationId): $e');
    }
  }

  /// Realtime listener untuk notifikasi disposisi baru pengguna
  static void listenDisposisiRealtime(
    String userId,
    Function(NotificationModel) onNewNotification,
  ) {
    supabase
        .channel('disposisi-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) async {
            final data = payload.newRecord;
            final notif = NotificationModel.fromJson(data);
            
            // Tampilkan pop-up lokal
            await showNotification(
              title: notif.title,
              body: notif.message,
            );

            onNewNotification(notif);
          },
        )
        .subscribe();
  }
}