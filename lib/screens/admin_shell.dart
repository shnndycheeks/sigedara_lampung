import 'package:flutter/material.dart';

import '../services/navigation_service.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

import 'admin_aset_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_kendaraan_screen.dart';
import 'admin_laporan_screen.dart';
import 'admin_peminjaman_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_surat_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final int _pendingCount = 5;

  final Map<int, Widget> _screenCache = {};
  final Set<int> _visitedIndices = {0};

  // ============================================================
  // PERMISSION
  // ============================================================

  /// Mengecek apakah tab tertentu boleh diakses
  /// berdasarkan PermissionService.
  bool _canAccessTab(int index) {
    switch (index) {
      case 0:
        // Dashboard
        return PermissionService.canAccessDashboard;

      case 1:
        // Peminjaman
        return PermissionService.canAccessPeminjaman;

      case 2:
        // Kendaraan
        return PermissionService.canAccessKendaraan;

      case 3:
        // Aset / Gedung
        return PermissionService.canAccessAset;

      case 4:
        // Laporan Kerusakan Kendaraan
        return PermissionService.canAccessLaporanKendaraan;

      case 5:
        // Profil
        return PermissionService.canAccessProfile;

      case 6:
        // Arsip Surat
        return PermissionService.canAccessSurat;

      default:
        return false;
    }
  }

  // ============================================================
  // SCREEN BUILDER
  // ============================================================

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardScreen();

      case 1:
        return const AdminPeminjamanScreen();

      case 2:
        return const AdminKendaraanScreen();

      case 3:
        return AdminAsetScreen(onBack: () => setState(() => _currentIndex = 0));

      case 4:
        // Laporan Kerusakan Kendaraan
        return const AdminLaporanScreen();

      case 5:
        return const AdminProfileScreen();

      case 6:
        return const AdminSuratScreen();

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    NavigationService.goHomeAdmin = goHome;
    NavigationService.goToTabAdmin = goToTab;
  }

  @override
  void dispose() {
    NavigationService.goHomeAdmin = null;
    NavigationService.goToTabAdmin = null;

    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void goHome() {
    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
    });
  }

  void goToTab(int index) {
    if (!_canAccessTab(index)) {
      debugPrint('Permission ditolak untuk tab index: $index');
      return;
    }

    if (!mounted) return;

    setState(() {
      _currentIndex = index;
    });
  }

  void _changeTab(int index) {
    if (!_canAccessTab(index)) {
      debugPrint('Permission ditolak untuk tab index: $index');
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Pengaman tambahan.
    //
    // Kalau somehow currentIndex menunjuk ke halaman
    // yang tidak boleh diakses, kembali ke Dashboard.
    if (!_canAccessTab(_currentIndex)) {
      _currentIndex = 0;
    }

    _visitedIndices.add(_currentIndex);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(7, (i) {
            if (!_visitedIndices.contains(i)) {
              return const SizedBox.shrink();
            }

            if (i == 0 || i == 1 || i == 6) {
              _screenCache[i] = _buildScreen(i);
            } else {
              _screenCache.putIfAbsent(i, () => _buildScreen(i));
            }

            return Offstage(
              offstage: i != _currentIndex,
              child: _screenCache[i]!,
            );
          }),
        ),

        // ========================================================
        // BOTTOM NAVIGATION
        // ========================================================
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Color(0x14D4AF37),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // ==================================================
                  // DASHBOARD
                  // ==================================================
                  if (PermissionService.canAccessDashboard)
                    _AdminNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Dashboard',
                      index: 0,
                      current: _currentIndex,
                      onTap: _changeTab,
                    ),

                  // ==================================================
                  // PEMINJAMAN
                  // ==================================================
                  if (PermissionService.canAccessPeminjaman)
                    _AdminNavItem(
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment,
                      label: 'Peminjaman',
                      index: 1,
                      current: _currentIndex,
                      onTap: _changeTab,
                      badge: _pendingCount,
                    ),

                  // ==================================================
                  // KENDARAAN
                  // HANYA ADMIN KENDARAAN
                  // ==================================================
                  if (PermissionService.canAccessKendaraan)
                    _AdminNavItem(
                      icon: Icons.directions_car_outlined,
                      activeIcon: Icons.directions_car,
                      label: 'Kendaraan',
                      index: 2,
                      current: _currentIndex,
                      onTap: _changeTab,
                    ),

                  // ==================================================
                  // ASET / GEDUNG
                  // HANYA ADMIN GEDUNG
                  // ==================================================
                  if (PermissionService.canAccessAset)
                    _AdminNavItem(
                      icon: Icons.inventory_2_outlined,
                      activeIcon: Icons.inventory_2,
                      label: 'Aset',
                      index: 3,
                      current: _currentIndex,
                      onTap: _changeTab,
                    ),

                  // ==================================================
                  // ARSIP SURAT
                  // ==================================================
                  if (PermissionService.canAccessSurat)
                    _AdminNavItem(
                      icon: Icons.mail_outline_rounded,
                      activeIcon: Icons.mail_rounded,
                      label: 'Arsip Surat',
                      index: 6,
                      current: _currentIndex,
                      onTap: _changeTab,
                    ),

                  // ==================================================
                  // PROFIL
                  // ==================================================
                  if (PermissionService.canAccessProfile)
                    _AdminNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profil',
                      index: 5,
                      current: _currentIndex,
                      onTap: _changeTab,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================================================================
// ADMIN NAV ITEM
// ==================================================================

class _AdminNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final int badge;

  const _AdminNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = index == current;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: active ? 6 : 2,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    active ? activeIcon : icon,
                    color: active
                        ? const Color(0xFFF59E0B)
                        : AppColors.textHint,
                    size: 22,
                  ),

                  if (badge > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? const Color(0xFFF59E0B) : AppColors.textHint,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
