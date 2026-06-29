import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/navigation_service.dart';
import 'dashboard_screen.dart';
import 'peminjaman_screen.dart';
import 'kendaraan_screen.dart';
import 'pengingat_screen.dart';
import 'laporan_kerusakan_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final int _notifCount = 3;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    NavigationService.goHomeUser = goHome;
    NavigationService.goToTabUser = goToTab;
    _screens = [
      const DashboardScreen(),
      const PeminjamanScreen(),
      const KendaraanScreen(),
      const PengingatScreen(),
      const LaporanKerusakanScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    NavigationService.goHomeUser = null;
    NavigationService.goToTabUser = null;
    super.dispose();
  }

  void goHome() => setState(() => _currentIndex = 0);

  void goToTab(int index) => setState(() => _currentIndex = index);

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
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _NavItem(
                    icon: Icons.business_outlined,
                    activeIcon: Icons.business,
                    label: 'Pinjam',
                    index: 1,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                    badge: _notifCount,
                  ),
                  _NavItem(
                    icon: Icons.directions_car_outlined,
                    activeIcon: Icons.directions_car,
                    label: 'Kendaraan',
                    index: 2,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications,
                    label: 'Pengingat',
                    index: 3,
                    current: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  final int badge;
  const _NavItem({
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
              ? AppColors.primary.withValues(alpha: 0.10)
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
                  color: active ? AppColors.primary : AppColors.textHint,
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
                color: active ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
