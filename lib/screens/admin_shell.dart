import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_peminjaman_screen.dart';
import 'admin_kendaraan_screen.dart';
import 'admin_aset_screen.dart';
import 'admin_laporan_screen.dart';
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
        return const AdminLaporanScreen();
      case 5:
        return const AdminProfileScreen();
      case 6:
        return const AdminSuratScreen();
      default:
        return const SizedBox.shrink();
    }
  }

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

  void goHome() => setState(() => _currentIndex = 0);

  void goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    _visitedIndices.add(_currentIndex);
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(7, (i) {
            if (!_visitedIndices.contains(i)) return const SizedBox.shrink();
            _screenCache.putIfAbsent(i, () => _buildScreen(i));
            return Offstage(
              offstage: i != _currentIndex,
              child: _screenCache[i]!,
            );
          }),
        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _AdminNavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    index: 0,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _AdminNavItem(
                    icon: Icons.meeting_room_outlined,
                    activeIcon: Icons.meeting_room,
                    label: 'Peminjaman',
                    index: 1,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                    badge: _pendingCount,
                  ),
                  _AdminNavItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car,
                    label: 'Kendaraan',
                    index: 2,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _AdminNavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    label: 'Aset',
                    index: 3,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _AdminNavItem(
                    icon: Icons.mail_outline_rounded,
                    activeIcon: Icons.mail_rounded,
                    label: 'Arsip Surat',
                    index: 6,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _AdminNavItem(
                    icon: Icons.manage_accounts_outlined,
                    activeIcon: Icons.manage_accounts,
                    label: 'Profil',
                    index: 5,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
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
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.gold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  color: active ? AppColors.gold : AppColors.textHint,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      width: 16,
                      height: 16,
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
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.gold : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
