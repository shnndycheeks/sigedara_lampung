import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../services/database_service.dart';

class EditPeminjamanGedungScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditPeminjamanGedungScreen({super.key, required this.data});

  @override
  State<EditPeminjamanGedungScreen> createState() =>
      _EditPeminjamanGedungScreenState();
}

class _EditPeminjamanGedungScreenState
    extends State<EditPeminjamanGedungScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tujuanCtrl = TextEditingController();
  final _pesertaCtrl = TextEditingController();

  final SupabaseClient _client = Supabase.instance.client;

  bool _loadingRuangan = true;
  bool _saving = false;

  List<Map<String, dynamic>> _ruanganList = [];
  String? _selectedRuanganId;

  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  @override
  void initState() {
    super.initState();

    _tujuanCtrl.text = (widget.data['tujuan'] ?? '').toString();
    _pesertaCtrl.text = (widget.data['peserta'] ?? '').toString();

    final tanggalMulai = DateTime.tryParse(
      (widget.data['tanggal_mulai'] ?? '').toString(),
    );

    final tanggalSelesai = DateTime.tryParse(
      (widget.data['tanggal_selesai'] ?? '').toString(),
    );

    if (tanggalMulai != null) {
      _selectedDate = tanggalMulai;
      _jamMulai = TimeOfDay(
        hour: tanggalMulai.hour,
        minute: tanggalMulai.minute,
      );
    }

    if (tanggalSelesai != null) {
      _jamSelesai = TimeOfDay(
        hour: tanggalSelesai.hour,
        minute: tanggalSelesai.minute,
      );
    }

    _selectedRuanganId = (widget.data['item_id'] ?? '').toString().trim();
    if (_selectedRuanganId!.isEmpty) {
      _selectedRuanganId = null;
    }

    _loadRuangan();
  }

  @override
  void dispose() {
    _tujuanCtrl.dispose();
    _pesertaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRuangan() async {
    try {
      final data = await DatabaseService.getRuangan();

      if (!mounted) return;

      setState(() {
        _ruanganList = List<Map<String, dynamic>>.from(data);
        _loadingRuangan = false;

        if (_selectedRuanganId == null && _ruanganList.isNotEmpty) {
          final currentName = (widget.data['ruangan'] ?? '').toString();

          final matched = _ruanganList.where((item) {
            final nama = _namaRuangan(item);
            return nama.toLowerCase() == currentName.toLowerCase();
          }).toList();

          if (matched.isNotEmpty) {
            _selectedRuanganId = matched.first['id'].toString();
          } else {
            _selectedRuanganId = _ruanganList.first['id'].toString();
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingRuangan = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat ruangan: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _namaRuangan(Map<String, dynamic> item) {
    return (item['nama'] ??
            item['nama_ruangan'] ??
            item['ruangan'] ??
            item['name'] ??
            'Tanpa Nama')
        .toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Pilih jam';

    return '${time.hour.toString().padLeft(2, '0')}.'
        '${time.minute.toString().padLeft(2, '0')} WIB';
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (result == null) return;

    setState(() => _selectedDate = result);
  }

  Future<void> _pickJamMulai() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (result == null) return;

    setState(() => _jamMulai = result);
  }

  Future<void> _pickJamSelesai() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _jamSelesai ?? const TimeOfDay(hour: 10, minute: 0),
    );

    if (result == null) return;

    setState(() => _jamSelesai = result);
  }

  Future<void> _save() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedRuanganId == null || _selectedRuanganId!.isEmpty) {
      _showMessage('Ruangan wajib dipilih');
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Tanggal wajib dipilih');
      return;
    }

    if (_jamMulai == null || _jamSelesai == null) {
      _showMessage('Jam mulai dan jam selesai wajib dipilih');
      return;
    }

    final tanggalMulai = _combineDateAndTime(_selectedDate!, _jamMulai!);
    final tanggalSelesai = _combineDateAndTime(_selectedDate!, _jamSelesai!);

    if (!tanggalSelesai.isAfter(tanggalMulai)) {
      _showMessage('Jam selesai harus lebih besar dari jam mulai');
      return;
    }

    final id = (widget.data['id'] ?? '').toString().trim();

    if (id.isEmpty) {
      _showMessage('ID peminjaman tidak ditemukan');
      return;
    }

    final peserta = int.tryParse(_pesertaCtrl.text.trim());

    if (peserta == null || peserta <= 0) {
      _showMessage('Jumlah peserta harus angka lebih dari 0');
      return;
    }

    final tujuan = _tujuanCtrl.text.trim();

    if (tujuan.isEmpty) {
      _showMessage('Tujuan wajib diisi');
      return;
    }

    final selectedRuangan = _ruanganList.firstWhere(
      (item) => item['id'].toString() == _selectedRuanganId,
      orElse: () => <String, dynamic>{},
    );

    final namaRuangan = selectedRuangan.isEmpty
        ? (widget.data['ruangan'] ?? '').toString()
        : _namaRuangan(selectedRuangan);

    final keperluanLengkap =
        '$tujuan | Peserta: $peserta | Ruangan: $namaRuangan';

    setState(() => _saving = true);

    try {
      debugPrint('===== DEBUG EDIT PEMINJAMAN GEDUNG =====');
      debugPrint('ID EDIT PEMINJAMAN: $id');
      debugPrint('RUANGAN BARU: $_selectedRuanganId');
      debugPrint('NAMA RUANGAN BARU: $namaRuangan');
      debugPrint('TUJUAN BARU: $tujuan');
      debugPrint('KEPERLUAN LENGKAP: $keperluanLengkap');
      debugPrint('PESERTA BARU: $peserta');
      debugPrint('TANGGAL MULAI BARU: ${tanggalMulai.toIso8601String()}');
      debugPrint('TANGGAL SELESAI BARU: ${tanggalSelesai.toIso8601String()}');

      final updated = await _client
          .from('peminjaman')
          .update({
            'item_id': _selectedRuanganId,
            'keperluan': keperluanLengkap,
            'peserta': peserta,
            'tanggal_mulai': tanggalMulai.toIso8601String(),
            'tanggal_selesai': tanggalSelesai.toIso8601String(),
          })
          .eq('id', id)
          .select(
            'id, item_id, keperluan, peserta, tanggal_mulai, tanggal_selesai',
          );

      debugPrint('HASIL UPDATE PEMINJAMAN: $updated');

      if (updated.isEmpty) {
        throw Exception(
          'Data tidak berubah. Kemungkinan ID tidak ditemukan atau akses update ditolak oleh RLS.',
        );
      }

      final pesertaHasil = updated.first['peserta'];

      if (pesertaHasil.toString() != peserta.toString()) {
        throw Exception(
          'Peserta gagal berubah. Dikirim: $peserta, hasil Supabase: $pesertaHasil',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Peminjaman berhasil diperbarui'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui peminjaman: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Peminjaman Gedung'),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data Ruangan',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 16),
                      _loadingRuangan
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedRuanganId,
                              isExpanded: true,
                              decoration: _inputDecoration(
                                label: 'Ruangan',
                                icon: Icons.meeting_room_outlined,
                              ),
                              items: _ruanganList.map((item) {
                                final id = item['id'].toString();

                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(
                                    _namaRuangan(item),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedRuanganId = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ruangan wajib dipilih';
                                }

                                return null;
                              },
                            ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tujuanCtrl,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          label: 'Tujuan / Keperluan',
                          icon: Icons.description_outlined,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Tujuan wajib diisi';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pesertaCtrl,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Jumlah Peserta',
                          icon: Icons.people_outline,
                        ),
                        validator: (value) {
                          final peserta = int.tryParse((value ?? '').trim());

                          if (peserta == null || peserta <= 0) {
                            return 'Jumlah peserta harus angka';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Peminjaman',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 16),
                      _pickTile(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal',
                        value: _formatDate(_selectedDate),
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _pickTile(
                              icon: Icons.access_time,
                              label: 'Jam Mulai',
                              value: _formatTime(_jamMulai),
                              onTap: _pickJamMulai,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pickTile(
                              icon: Icons.access_time_filled_outlined,
                              label: 'Jam Selesai',
                              value: _formatTime(_jamSelesai),
                              onTap: _pickJamSelesai,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.55),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _pickTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}