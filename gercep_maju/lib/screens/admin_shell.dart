import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_persetujuan_screen.dart';
import 'admin_kendaraan_screen.dart';
import 'admin_aset_screen.dart';
import 'admin_laporan_screen.dart';
import 'admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => AdminShellState();
}

class AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  int _pendingCount = 5;

  @override
  void initState() {
    super.initState();
    NavigationService.goHomeAdmin = goHome;
  }

  @override
  void dispose() {
    NavigationService.goHomeAdmin = null;
    super.dispose();
  }

  void goHome() => setState(() => _currentIndex = 0);

  void goToTab(int index) => setState(() => _currentIndex = index);

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminPersetujuanScreen(),
    AdminKendaraanScreen(),
    AdminAsetScreen(),
    AdminLaporanScreen(),
    AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
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
                    icon: Icons.approval_outlined,
                    activeIcon: Icons.approval,
                    label: 'Persetujuan',
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
                    icon: Icons.report_problem_outlined,
                    activeIcon: Icons.report_problem,
                    label: 'Laporan',
                    index: 4,
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
