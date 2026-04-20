import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../features/input/transaction_input_sheet.dart';
import '../core/services/graduation_service.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/report')) return 1; // report is a review action/output
    return 0; // dashboard + settings keep the left tab selected
  }

  @override
  Widget build(BuildContext context) {
    // Get current location safely
    final location = GoRouter.of(context)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();
    final idx = _currentIndex(location);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _BottomNav(
        currentIndex: idx,
        onTap: (i) {
          if (i == 1) {
            context.go('/history');
            return;
          }
          if (i == 0) {
            context.go('/dashboard');
            return;
          }

          if (GraduationService.isGraduated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('账单已封存：已毕业，无法继续记账'),
                backgroundColor: AppColors.surface,
              ),
            );
            return;
          }

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const TransactionInputSheet(),
          );
        },
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _NavItem(
                          icon: Icons.show_chart,
                          label: '大盘',
                          selected: currentIndex == 0,
                          onTap: () => onTap(0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 72),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _NavItem(
                          icon: Icons.receipt_long_outlined,
                          label: '复盘',
                          selected: currentIndex == 1,
                          onTap: () => onTap(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -18,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AddButton(onTap: () => onTap(2)),
                    const SizedBox(height: 2),
                    Text(
                      '记一笔',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                        fontWeight: currentIndex == 0 || currentIndex == 1
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: AppColors.expense,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 4),
          boxShadow: [
            BoxShadow(color: AppColors.expense.withAlpha(70), blurRadius: 14, offset: const Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}
