import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
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
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final nip = _nipCtrl.text.trim();

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
      final pegawai = await _verifyNipPegawai(nip);

      if (pegawai == null) {
        if (!mounted) return;

        setState(() => _loading = false);
        _showSnack(
          'NIP tidak terdaftar sebagai pegawai. Akun tidak dapat dibuat.',
          AppColors.error,
        );
        return;
      }
      _namaCtrl.text = pegawai['nama'] ?? '';
      _jabatanCtrl.text = pegawai['jabatan'] ?? '';

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama': pegawai['nama'],
          'role': pegawai['role'],
          'role_id': pegawai['role_id'],
          'jabatan': pegawai['jabatan'],
          'jabatan_id': pegawai['jabatan_id'],
          'nip': nip,
        },
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Gagal membuat akun. Coba lagi.');
      }

      await _client.from('profiles').insert({
        'id': user.id,
        'nama': pegawai['nama'],
        'email': email,
        'role': pegawai['role'],
        'role_id': pegawai['role_id'],
        'nip': nip,
        'jabatan': pegawai['jabatan'],
        'jabatan_id': pegawai['jabatan_id'],
      });

      if (!mounted) return;

      setState(() => _loading = false);

      _showSnack('Akun berhasil dibuat. Silakan login.', AppColors.success);

      await Future.delayed(const Duration(milliseconds: 900));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(isAdmin: false)),
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

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,}$');
    return regex.hasMatch(value);
  }

  bool _isValidNip(String value) {
    final regex = RegExp(r'^[0-9]{18}$');
    return regex.hasMatch(value);
  }

  Future<Map<String, dynamic>?> _verifyNipPegawai(String nip) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final dummyPegawai = [
      {
        'nip': '198007201999121002',
        'nama': 'MUHAMMAD YULIARDI, S.STP., M.Si.',
        'jabatan': 'Kepala Biro Umum',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'karo',
      },
      {
        'nip': '197510042010011002',
        'nama': 'ALVIRDIAN OKTAFIANUS, S.E., S.T., M.M.',
        'jabatan': 'Kepala Bagian Rumah Tangga',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'kabag_rt_jab',
      },
      {
        'nip': '200004122021081001',
        'nama': 'MUHAMMAD FADHEL PUSVA NEGARA, S.Tr.Ip',
        'jabatan': 'Ketua Tim Kendaraan Dinas',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'katim_kd_jab',
      },
      {
        'nip': '198711092011011010',
        'nama': 'RICKO PAHLEVI, S.IP',
        'jabatan': 'Ketua Tim Gedung 1',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'katim_gd_jab',
      },
      {
        'nip': '199003262010101002',
        'nama': 'WAHYUDI SAPUTRA, S.STP, M.Si.',
        'jabatan': 'Ketua Tim Gedung 2',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'katim_gd_jab',
      },
      {
        'nip': '197906092002121003',
        'nama': 'HARRY KURNIAWANSYAH, SP., M.M.',
        'jabatan': 'Ketua Tim Urusan Dalam',
        'role': 'pegawai',
        'role_id': 'pegawai',
        'jabatan_id': 'katim_ud_jab',
      },
      {
        'nip': '199904062025041008',
        'nama': 'ENGGAL ALFRIAN, S.Kom.',
        'jabatan': 'Admin Bagian Kendaraan Dinas',
        'role': 'admin',
        'role_id': 'admin',
        'jabatan_id': 'admin_kendaraan',
      },
      {
        'nip': '198903292025212025',
        'nama': 'ANI RIANA, S.Kom',
        'jabatan': 'Admin Bagian Gedung',
        'role': 'admin',
        'role_id': 'admin',
        'jabatan_id': 'admin_gedung',
      },
    ];

    try {
      return dummyPegawai.firstWhere((pegawai) => pegawai['nip'] == nip);
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF0B224A),
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFF5B6B84).withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          prefixIcon: Icon(prefixIcon, color: const Color(0xFF0284C7)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: _obscure,
        maxLength: 32,
        textInputAction: TextInputAction.next,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF0B224A),
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Minimal 6 karakter',
          hintStyle: TextStyle(
            color: const Color(0xFF5B6B84).withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0284C7)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: const Color(0xFF0284C7).withValues(alpha: 0.7),
            ),
            onPressed: () {
              setState(() => _obscure = !_obscure);
            },
          ),
        ),
      ),
    );
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

              // Dynamic Aurora (Pegawai colors)
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

              // Content
              Positioned.fill(
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 0,
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

                          SizedBox(
                            width: 280,
                            height: 95,
                            child: Image.asset(
                              'assets/images/logo_biro_noBG.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text(
                            'SIMASTER Lampung',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 2),

                          const Text(
                            'Pendaftaran Akun Pegawai',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ================= FORM =================
                          FadeTransition(
                            opacity: _fadeAnim,
                            child: SlideTransition(
                              position: _slideAnim,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                                        color: Colors.white.withValues(
                                          alpha: 0.75,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF0284C7,
                                          ).withValues(alpha: 0.4),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF0284C7,
                                            ).withValues(alpha: 0.08),
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
                                            'Buat Akun',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF0B224A),
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          const Text(
                                            'Nama Lengkap *',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B6B84),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInputField(
                                            controller: _namaCtrl,
                                            readOnly: true,
                                            hint: 'Nama akan muncul otomatis',
                                            prefixIcon: Icons.person_outline,
                                            maxLength: 60,
                                            keyboardType: TextInputType.name,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.allow(
                                                RegExp(r"[a-zA-ZÀ-ÿ\s'.-]"),
                                              ),
                                              LengthLimitingTextInputFormatter(
                                                60,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          const Text(
                                            'Email *',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B6B84),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInputField(
                                            controller: _emailCtrl,
                                            hint: 'contoh: pegawai@email.com',
                                            prefixIcon: Icons.email_outlined,
                                            maxLength: 80,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                80,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          const Text(
                                            'Password *',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B6B84),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildPasswordField(),
                                          const SizedBox(height: 16),

                                          const Text(
                                            'NIP *',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B6B84),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInputField(
                                            controller: _nipCtrl,
                                            hint: 'Masukkan 18 digit NIP',
                                            prefixIcon: Icons.badge_outlined,
                                            maxLength: 18,
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                18,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),

                                          const Text(
                                            'Jabatan / Unit',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF5B6B84),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildInputField(
                                            controller: _jabatanCtrl,
                                            readOnly: true,
                                            hint:
                                                'Jabatan akan muncul otomatis',
                                            prefixIcon: Icons.work_outline,
                                            maxLength: 60,
                                            textCapitalization:
                                                TextCapitalization.words,
                                            inputFormatters: [
                                              LengthLimitingTextInputFormatter(
                                                60,
                                              ),
                                            ],
                                            textInputAction:
                                                TextInputAction.done,
                                          ),
                                          const SizedBox(height: 24),

                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: ElevatedButton(
                                              onPressed: _loading
                                                  ? null
                                                  : _register,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF0284C7,
                                                ),
                                                foregroundColor: Colors.white,
                                                shadowColor: const Color(
                                                  0xFF0284C7,
                                                ).withValues(alpha: 0.5),
                                                elevation: 4,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: _loading
                                                  ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                    )
                                                  : const Text(
                                                      'Daftar Akun',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontFamily: 'Poppins',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                            ),
                                          ),

                                          const SizedBox(height: 10),

                                          Center(
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const LoginScreen(
                                                          isAdmin: false,
                                                        ),
                                                  ),
                                                );
                                              },
                                              child: RichText(
                                                text: const TextSpan(
                                                  style: TextStyle(
                                                    color: Color(0xFF5B6B84),
                                                    fontSize: 13,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          'Sudah punya akun? ',
                                                    ),
                                                    TextSpan(
                                                      text: 'Masuk',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF0369A1,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
            ],
          ),
        ),
      ),
    );
  }
}
