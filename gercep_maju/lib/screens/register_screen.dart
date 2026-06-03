import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nipCtrl = TextEditingController();
  final _jabatanCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final SupabaseClient _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
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
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nipCtrl.dispose();
    _jabatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nama = _namaCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final nip = _nipCtrl.text.trim();
    final jabatan = _jabatanCtrl.text.trim();

    if (nama.isEmpty) {
      _showSnack('Nama lengkap wajib diisi', AppColors.error);
      return;
    }

    if (nama.length < 3) {
      _showSnack('Nama lengkap minimal 3 karakter', AppColors.error);
      return;
    }

    if (nama.length > 60) {
      _showSnack('Nama lengkap maksimal 60 karakter', AppColors.error);
      return;
    }

    if (!_isValidName(nama)) {
      _showSnack(
        'Nama hanya boleh berisi huruf, spasi, titik, petik, dan strip',
        AppColors.error,
      );
      return;
    }

    if (email.isEmpty) {
      _showSnack('Email wajib diisi', AppColors.error);
      return;
    }

    if (email.length > 80) {
      _showSnack('Email maksimal 80 karakter', AppColors.error);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnack('Format email tidak valid', AppColors.error);
      return;
    }

    if (password.isEmpty) {
      _showSnack('Password wajib diisi', AppColors.error);
      return;
    }

    if (password.length < 6) {
      _showSnack('Password minimal 6 karakter', AppColors.error);
      return;
    }

    if (password.length > 32) {
      _showSnack('Password maksimal 32 karakter', AppColors.error);
      return;
    }

    if (nip.isEmpty) {
      _showSnack('NIP wajib diisi untuk verifikasi pegawai', AppColors.error);
      return;
    }

    if (!_isValidNip(nip)) {
      _showSnack('NIP harus berupa 18 digit angka', AppColors.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final isNipValid = await _verifyNipPegawai(nip);

      if (!isNipValid) {
        if (!mounted) return;

        setState(() => _loading = false);
        _showSnack(
          'NIP tidak terdaftar sebagai pegawai. Akun tidak dapat dibuat.',
          AppColors.error,
        );
        return;
      }

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama': nama,
          'role': 'pegawai',
          'nip': nip,
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Gagal membuat akun. Coba lagi.');
      }

      await _client.from('profiles').insert({
        'id': user.id,
        'nama': nama,
        'email': email,
        'role': 'pegawai',
        'nip': nip,
        'jabatan': jabatan.isEmpty ? null : jabatan,
      });

      if (!mounted) return;

      setState(() => _loading = false);

      _showSnack('Akun berhasil dibuat. Silakan login.', AppColors.success);

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(isAdmin: false),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showSnack(e.message, AppColors.error);
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showSnack('Gagal daftar akun: $e', AppColors.error);
    }
  }

  bool _isValidName(String value) {
    final regex = RegExp(r"^[a-zA-ZÀ-ÿ\s'.-]+$");
    return regex.hasMatch(value);
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
    return regex.hasMatch(value);
  }

  bool _isValidNip(String value) {
    final regex = RegExp(r'^[0-9]{18}$');
    return regex.hasMatch(value);
  }

  Future<bool> _verifyNipPegawai(String nip) async {
    await Future.delayed(const Duration(milliseconds: 800));

    /*
      INI MASIH DUMMY UNTUK TESTING.

      Nanti kalau kamu sudah punya API resmi/BACKEND untuk cek NIP,
      isi function ini bisa diganti.

      Contoh alur nanti:
      Flutter -> Backend kamu / Supabase Edge Function -> API BKN

      Jangan taruh token API BKN langsung di Flutter.
    */

    final dummyNipPegawai = [
      '198501012010011001',
      '199001012015021002',
      '199503152020121003',
    ];

    return dummyNipPegawai.contains(nip);
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
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
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordCtrl,
      obscureText: _obscure,
      maxLength: 32,
      textInputAction: TextInputAction.next,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Minimal 6 karakter',
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
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscure = !_obscure);
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 360,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bg.jpg'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.18),
              AppColors.primaryDark.withValues(alpha: 0.72),
              AppColors.primary.withValues(alpha: 0.82),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 45),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logo_noBG.png',
                      width: 210,
                      height: 105,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftar Akun Pegawai',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SIGEDARA LAMPUNG',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistem Informasi Gedung dan Kendaraan Lampung',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        height: 1.3,
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard() {
    return NeuCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Buat Akun', style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(
            'Isi data pegawai untuk membuat akun baru',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),

          const Text(
            'Nama Lengkap *',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _namaCtrl,
            hint: 'Maksimal 60 karakter',
            prefixIcon: Icons.person_outline,
            maxLength: 60,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-ZÀ-ÿ\s'.-]"),
              ),
              LengthLimitingTextInputFormatter(60),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Email *',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _emailCtrl,
            hint: 'contoh: pegawai@email.com',
            prefixIcon: Icons.email_outlined,
            maxLength: 80,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              LengthLimitingTextInputFormatter(80),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Password *',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          _buildPasswordField(),
          const SizedBox(height: 16),

          const Text(
            'NIP *',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _nipCtrl,
            hint: 'Masukkan 18 digit NIP',
            prefixIcon: Icons.badge_outlined,
            maxLength: 18,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Jabatan / Unit',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 6),
          _buildInputField(
            controller: _jabatanCtrl,
            hint: 'Contoh: Staf Biro Umum',
            prefixIcon: Icons.work_outline,
            maxLength: 60,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              LengthLimitingTextInputFormatter(60),
            ],
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'Daftar Akun',
              icon: Icons.person_add_alt_1,
              isLoading: _loading,
              onPressed: _register,
              gradientColors: const [
                AppColors.primaryLight,
                AppColors.primary,
              ],
              shadowColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),

          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(isAdmin: false),
                  ),
                );
              },
              child: Text(
                'Sudah punya akun? Masuk',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 320),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: _buildRegisterCard(),
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