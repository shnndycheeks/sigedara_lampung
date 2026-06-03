import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'admin_shell.dart';
import 'main_shell.dart';
import 'register_screen.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdmin;

  const LoginScreen({super.key, this.isAdmin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Color get _primaryColor =>
      widget.isAdmin ? const Color(0xFFD4AF37) : const Color(0xFF0B63CE);

  Color get _primaryDark =>
      widget.isAdmin ? const Color(0xFF8B6A00) : const Color(0xFF064AA8);

  List<Color> get _gradient {
    if (widget.isAdmin) {
      return const [Color(0xFF6B5200), Color(0xFFD4AF37)];
    }

    return const [Color(0xFF063F98), Color(0xFF0E6AD8)];
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Lupa Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Silakan hubungi administrator untuk reset password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email dan password wajib diisi', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.login(email: email, password: password);

      final expectedRole = widget.isAdmin ? UserRole.admin : UserRole.user;

      final currentRole = AuthService.currentRole.value;

      if (currentRole != expectedRole) {
        await AuthService.logout();

        throw Exception(
          widget.isAdmin
              ? 'Akun ini bukan Administrator'
              : 'Akun ini bukan Pegawai',
        );
      }

      if (!mounted) return;

      _showMessage('Login berhasil');
      await AppNotificationService.showNotification(
        title: 'Login Berhasil',
        body: 'Selamat datang di SIGEDARA',
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              widget.isAdmin ? const AdminShell() : const MainShell(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Terjadi kesalahan';

      final error = e.toString().toLowerCase();

      if (error.contains('invalid login credentials')) {
        errorMessage = 'Email atau password salah';
      } else if (error.contains('administrator')) {
        errorMessage = 'Akun ini bukan Administrator';
      } else if (error.contains('pegawai')) {
        errorMessage = 'Akun ini bukan Pegawai';
      } else if (error.contains('network')) {
        errorMessage = 'Koneksi internet bermasalah';
      }

      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FC),

        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Container(
                          width: 290,
                          height: 90,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_biro_umum.png',
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Sigedara Lampung',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          widget.isAdmin
                              ? 'Portal Administrator Sistem'
                              : 'Sistem Pengelolaan Aset & Peminjaman',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // ================= FORM =================
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Masuk',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0B224A),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.isAdmin
                              ? 'Masuk sebagai Administrator'
                              : 'Masuk sebagai Pegawai',
                          style: const TextStyle(
                            color: Color(0xFF5B6B84),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B6B84),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Masukkan email',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _primaryColor,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Password',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5B6B84),
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            hintText: 'Masukkan password',
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: _primaryColor,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF1F5FB),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: _primaryDark,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),

                            const Text(
                              'Ingat saya',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),

                            const Spacer(),

                            GestureDetector(
                              onTap: _showForgotPasswordDialog,
                              child: Text(
                                'Lupa password?',
                                style: TextStyle(
                                  color: _primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _login,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded),
                            label: Text(
                              _loading ? 'Memproses...' : 'Masuk',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryDark,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: const [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('atau'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _showMessage('Fitur biometrik segera hadir');
                            },
                            icon: Icon(Icons.fingerprint, color: _primaryDark),
                            label: Text(
                              'Masuk dengan Biometrik',
                              style: TextStyle(
                                color: _primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _primaryDark, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),

                        if (!widget.isAdmin) ...[
                          const SizedBox(height: 30),

                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Color(0xFF5B6B84),
                                  ),
                                  children: [
                                    const TextSpan(text: 'Belum punya akun? '),
                                    TextSpan(
                                      text: 'Daftar sekarang',
                                      style: TextStyle(
                                        color: _primaryDark,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        const Center(
                          child: Text(
                            'Sistem Internal — Biro Umum Setda Provinsi Lampung',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9AA7BA),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
