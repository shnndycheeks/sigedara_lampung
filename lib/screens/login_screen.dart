import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
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

      // SIMPAN STATUS INGAT SAYA
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', _rememberMe);

      if (!mounted) return;

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
        backgroundColor: AppColors.background,
        extendBodyBehindAppBar: true,

        body: SizedBox.expand(
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.asset('assets/images/bg.jpg', fit: BoxFit.cover),
              ),

              // Dynamic Aurora
              if (widget.isAdmin) ...[
                Positioned(
                  top: -100,
                  left: -50,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9A7A0A).withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  right: -100,
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4338CA).withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  right: -50,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE91E63).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ] else ...[
                Positioned(
                  top: -100,
                  left: -50,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0284C7).withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -150,
                  right: -100,
                  child: Container(
                    width: 450,
                    height: 450,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4338CA).withValues(alpha: 0.45),
                    ),
                  ),
                ),
                Positioned(
                  top: 150,
                  right: -50,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00D4FF).withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],

              // Glass Overlay
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.4),
                          Colors.white.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // ================= HEADER =================
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 4,
                          bottom: 8,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Container(
                              width: 280,
                              height: 90,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo_biro_umum.png',
                                fit: BoxFit.contain,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              'Sigedara Lampung',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              widget.isAdmin
                                  ? 'Portal Administrator Sistem'
                                  : 'Sistem Pengelolaan Aset & Peminjaman',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),

                      // ================= FORM =================
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: _primaryColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0B224A),
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        widget.isAdmin
                                            ? 'Masuk sebagai Administrator'
                                            : 'Masuk sebagai Pegawai',
                                        style: const TextStyle(
                                          color: Color(0xFF5B6B84),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      const Text(
                                        'Email',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B6B84),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _emailCtrl,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan email',
                                            hintStyle: TextStyle(
                                              color: const Color(
                                                0xFF5B6B84,
                                              ).withValues(alpha: 0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: _primaryColor,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0),
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: _primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B6B84),
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Container(
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.03,
                                              ),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _passwordCtrl,
                                          obscureText: _obscure,
                                          decoration: InputDecoration(
                                            hintText: 'Masukkan password',
                                            hintStyle: TextStyle(
                                              color: const Color(
                                                0xFF5B6B84,
                                              ).withValues(alpha: 0.5),
                                            ),
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
                                                color: _primaryColor.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: const BorderSide(
                                                color: Color(0xFFE2E8F0),
                                                width: 1.5,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: _primaryColor,
                                                width: 2,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

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
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
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
                                                  child:
                                                      CircularProgressIndicator(
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
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      Row(
                                        children: const [
                                          Expanded(child: Divider()),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
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
                                            _showMessage(
                                              'Fitur biometrik segera hadir',
                                            );
                                          },
                                          icon: Icon(
                                            Icons.fingerprint,
                                            color: _primaryDark,
                                          ),
                                          label: Text(
                                            'Masuk dengan Biometrik',
                                            style: TextStyle(
                                              color: _primaryDark,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: _primaryDark,
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (!widget.isAdmin) ...[
                                        const SizedBox(height: 16),

                                        Center(
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const RegisterScreen(),
                                                ),
                                              );
                                            },
                                            child: RichText(
                                              text: TextSpan(
                                                style: const TextStyle(
                                                  color: Color(0xFF5B6B84),
                                                ),
                                                children: [
                                                  const TextSpan(
                                                    text: 'Belum punya akun? ',
                                                  ),
                                                  TextSpan(
                                                    text: 'Daftar sekarang',
                                                    style: TextStyle(
                                                      color: _primaryDark,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 12),

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
                            ),
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
    );
  }
}
