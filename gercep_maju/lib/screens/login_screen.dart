import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'main_shell.dart';
import 'admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _rememberMe = false;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _loading = false);
      final username = _usernameCtrl.text.trim().toLowerCase();
      final isAdmin = username == 'admin';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isAdmin ? const AdminShell() : const MainShell(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/logo_biro_umum.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'GerCep Maju',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistem Pengelolaan Aset & Peminjaman',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form card
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 230),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: NeuCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Masuk', style: AppTextStyles.h2),
                            const SizedBox(height: 4),
                            Text(
                              'Silakan masuk dengan akun Anda',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 28),

                            // Username
                            const Text(
                              'Username / NIP',
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 6),
                            AppTextField(
                              hint: 'Masukkan username atau NIP',
                              prefixIcon: Icons.person_outline,
                              controller: _usernameCtrl,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            const Text('Password', style: AppTextStyles.label),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: AppTextStyles.body,
                              decoration: InputDecoration(
                                hintText: 'Masukkan password',
                                filled: true,
                                fillColor: AppColors.surfaceVariant,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.divider,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Remember + Forgot
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) => setState(
                                          () => _rememberMe = v ?? false,
                                        ),
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Ingat saya',
                                      style: AppTextStyles.label,
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    'Lupa password?',
                                    style: AppTextStyles.label.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Login button
                            SizedBox(
                              width: double.infinity,
                              child: GradientButton(
                                label: 'Masuk',
                                onPressed: _login,
                                isLoading: _loading,
                                icon: Icons.login,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Row(
                              children: [
                                const Expanded(
                                  child: Divider(color: AppColors.divider),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'atau',
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppColors.divider),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Biometric button
                            SizedBox(
                              width: double.infinity,
                              child: GradientButton(
                                label: 'Masuk dengan Biometrik',
                                onPressed: () {},
                                icon: Icons.fingerprint,
                                outlined: true,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Footer
                            Center(
                              child: Text(
                                'Sistem Internal — Biro Umum Setda Prov. Lampung\nHanya untuk pegawai resmi',
                                style: AppTextStyles.caption.copyWith(
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
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
          ),
        ],
      ),
    );
  }
}
