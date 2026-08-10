import 'role_model.dart';
import 'jabatan_model.dart';

class ProfileModel {
  final String id;
  final String nama;
  final String email;
  final String? nip;
  final String roleId;
  final String jabatanId;
  final String ttdPng;
  final String status;
  final DateTime createdAt;

  // Joined Master Data (Optional)
  final RoleModel? role;
  final JabatanModel? jabatan;

  ProfileModel({
    required this.id,
    required this.nama,
    required this.email,
    this.nip,
    required this.roleId,
    required this.jabatanId,
    required this.ttdPng,
    this.status = 'aktif',
    required this.createdAt,
    this.role,
    this.jabatan,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    RoleModel? parsedRole;
    if (json['roles'] is Map) {
      parsedRole = RoleModel.fromJson(Map<String, dynamic>.from(json['roles']));
    }

    JabatanModel? parsedJabatan;
    if (json['jabatan'] is Map) {
      parsedJabatan = JabatanModel.fromJson(Map<String, dynamic>.from(json['jabatan']));
    }

    return ProfileModel(
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      nip: json['nip']?.toString(),
      roleId: json['role_id'] ?? json['role'] ?? 'pegawai',
      jabatanId: json['jabatan_id'] ?? json['jabatan'] ?? 'tu_staff',
      ttdPng: json['ttd_png'] ?? 'signatures/default/ttd_karo.png',
      status: json['status'] ?? 'aktif',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      role: parsedRole,
      jabatan: parsedJabatan,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'nip': nip,
      'role_id': roleId,
      'jabatan_id': jabatanId,
      'ttd_png': ttdPng,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
