import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import 'app_background.dart';
import 'glass_card.dart';

class NavDestinationSpec {
  const NavDestinationSpec({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

const List<NavDestinationSpec> jarvisDestinations = [
  NavDestinationSpec(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Home'),
  NavDestinationSpec(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat'),
  NavDestinationSpec(icon: Icons.graphic_eq_rounded, activeIcon: Icons.graphic_eq_rounded, label: 'Voice'),
  NavDestinationSpec(icon: Icons.checklist_outlined, activeIcon: Icons.checklist_rounded, label: 'Tasks'),
  NavDestinationSpec(icon: Icons.bolt_outlined, activeIcon: Icons.bolt_rounded, label: 'Automate'),
  NavDestinationSpec(icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded, label: 'Memory'),
  NavDestinationSpec(icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book_rounded, label: 'Knowledge'),
  NavDestinationSpec(icon: Icons.insights_outlined, activeIcon: Icons.insights_rounded, label: 'Analytics'),
  NavDestinationSpec(icon: Icons.tune_rounded, activeIcon: Icons.tune_rounded, label: 'Settings'),
];

/// The app's persistent chrome: an ambient background plus a slim glass
/// icon rail (mirroring the reference design's left sidebar) that works
/// identically on phone and tablet — wraps a [StatefulNavigationShell] so
/// each branch keeps its own navigation stack and scroll position.
class NavShell extends StatelessWidget {
  const NavShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Row(
              children: [
                _GlassRail(currentIndex: navigationShell.currentIndex, onSelect: _onSelect, wide: wide),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSelect(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
}

class _GlassRail extends StatelessWidget {
  const _GlassRail({required this.currentIndex, required this.onSelect, required this.wide});

  final int currentIndex;
  final ValueChanged<int> onSelect;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final railWidth = wide ? 88.0 : 64.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, 0, AppSpacing.md),
      child: SizedBox(
        width: railWidth,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: AppColors.auroraGradient),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryGlow.withValues(alpha: 0.4), blurRadius: 16),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, size: 18, color: Colors.black),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: jarvisDestinations.length,
                  itemBuilder: (context, index) {
                    final spec = jarvisDestinations[index];
                    final selected = index == currentIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _RailItem(spec: spec, selected: selected, onTap: () => onSelect(index)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.spec, required this.selected, required this.onTap});

  final NavDestinationSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: spec.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryGlow.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: selected ? Border.all(color: AppColors.primaryGlow.withValues(alpha: 0.4)) : null,
          ),
          child: Icon(
            selected ? spec.activeIcon : spec.icon,
            size: 20,
            color: selected ? AppColors.primaryGlow : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
