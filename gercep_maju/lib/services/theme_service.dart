import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<bool> isDark = ValueNotifier(false);
}

class NotificationService {
  static final ValueNotifier<bool> notifPeminjaman = ValueNotifier(true);
  static final ValueNotifier<bool> notifPajak = ValueNotifier(true);
  static final ValueNotifier<bool> notifServis = ValueNotifier(false);
}
