import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_god_mode_resolver.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  static const _screenKeys = ['home', 'quran', 'tools', 'assistant_support'];

  void _go(BuildContext context, int visibleIndex, List<_ShellDestination> destinations) {
    final target = destinations[visibleIndex];
    final from = _screenKeys[navigationShell.currentIndex];
    final to = _screenKeys[target.branchIndex];

    context.read<AdService>().trackNavigation(
          context: context,
          fromScreenKey: from,
          toScreenKey: to,
        );

    navigationShell.goBranch(
      target.branchIndex,
      initialLocation: target.branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final godMode = context.watch<AppGodModeResolver>();
    final destinations = _visibleDestinations(godMode);
    final selectedVisibleIndex = destinations.indexWhere(
      (item) => item.branchIndex == navigationShell.currentIndex,
    );

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.nightBlue.withOpacity(.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.30),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedVisibleIndex < 0 ? 0 : selectedVisibleIndex,
              onDestinationSelected: (index) => _go(context, index, destinations),
              destinations: destinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ),
      ),
    );
  }

  List<_ShellDestination> _visibleDestinations(AppGodModeResolver godMode) {
    return [
      const _ShellDestination(
        branchIndex: 0,
        icon: Icons.home_rounded,
        label: AppStrings.navHome,
      ),
      const _ShellDestination(
        branchIndex: 1,
        icon: Icons.menu_book_rounded,
        label: AppStrings.navQuranHub,
      ),
      const _ShellDestination(
        branchIndex: 2,
        icon: Icons.explore_rounded,
        label: AppStrings.navToolsCompass,
      ),
      if (godMode.flags.isAiEnabled)
        const _ShellDestination(
          branchIndex: 3,
          icon: Icons.support_agent_rounded,
          label: AppStrings.navAssistantSupport,
        ),
    ];
  }
}

class _ShellDestination {
  final int branchIndex;
  final IconData icon;
  final String label;

  const _ShellDestination({
    required this.branchIndex,
    required this.icon,
    required this.label,
  });
}
