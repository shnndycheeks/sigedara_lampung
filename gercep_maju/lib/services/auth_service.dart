import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { guest, user, admin }

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  static final ValueNotifier<UserRole> currentRole = ValueNotifier(
    UserRole.guest,
  );

  static User? get currentUser => _client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  static Future<void> register({
    required String nama,
    required String email,
    required String password,
    UserRole role = UserRole.user,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama': nama,
        'role': role == UserRole.admin ? 'admin' : 'pegawai',
      },
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Gagal membuat akun');
    }

    final roleText = role == UserRole.admin ? 'admin' : 'pegawai';

    await _client.from('profiles').insert({
      'id': user.id,
      'nama': nama,
      'email': email,
      'role': roleText,
      'status': 'aktif',
    });

    currentRole.value = role;
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Email atau password salah');
    }

    await loadUserRole();

    if (currentRole.value == UserRole.guest) {
      await logout();
      throw Exception('Akun tidak memiliki role yang valid');
    }
  }

  static Future<void> loadUserRole() async {
    final user = currentUser;

    if (user == null) {
      currentRole.value = UserRole.guest;
      return;
    }

    final profile = await _client
        .from('profiles')
        .select('role, status')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      currentRole.value = UserRole.guest;
      return;
    }

    final role = profile['role']?.toString().toLowerCase();
    final status = (profile['status'] ?? 'aktif').toString().toLowerCase();

    if (status == 'nonaktif') {
      currentRole.value = UserRole.guest;
      await _client.auth.signOut();
      throw Exception('Akun Anda dinonaktifkan oleh admin');
    }

    if (role == 'admin') {
      currentRole.value = UserRole.admin;
    } else if (role == 'pegawai') {
      currentRole.value = UserRole.user;
    } else {
      currentRole.value = UserRole.guest;
    }
  }

  static Future<void> refreshSessionRole() async {
    await loadUserRole();
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
    currentRole.value = UserRole.guest;
  }

  static bool canAccessUserArea() {
    return currentRole.value == UserRole.user;
  }

  static bool canAccessAdminArea() {
    return currentRole.value == UserRole.admin;
  }

  // Ini dipertahankan sementara supaya kode lama kamu tidak langsung error.
  // Nanti kalau semua login sudah pakai database, bagian ini bisa dihapus.
  static void loginAs(UserRole role) {
    currentRole.value = role;
  }
}