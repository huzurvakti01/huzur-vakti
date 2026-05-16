import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/admin_theme.dart';
import '../services/auth_service.dart';
import 'absolute_moderation_screen.dart';
import 'ai_studio_screen.dart';
import 'cms_studio_screen.dart';
import 'dashboard_screen.dart';
import 'god_mode_studio.dart';
import 'kill_switch_screen.dart';
import 'login_screen.dart';
import 'support_tickets_screen.dart';
import 'user_matrix_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    DashboardScreen(),
    UserMatrixScreen(),
    AbsoluteModerationScreen(),
    KillSwitchScreen(),
    CmsStudioScreen(),
    GodModeStudioScreen(),
    AiStudioScreen(),
    SupportTicketsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.loading && !auth.isSignedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.isSignedIn) {
      return const LoginScreen();
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            minWidth: 92,
            backgroundColor: const Color(0xFF081714),
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 24),
              child: Image.asset(
                'assets/images/logo_main.png',
                width: 54,
                fit: BoxFit.contain,
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: IconButton(
                    tooltip: 'Çıkış',
                    onPressed: () => context.read<AuthService>().logout(),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_rounded),
                selectedIcon: Icon(Icons.dashboard_customize_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_rounded),
                selectedIcon: Icon(Icons.manage_accounts_rounded),
                label: Text('User Matrix'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shield_rounded),
                selectedIcon: Icon(Icons.gpp_maybe_rounded),
                label: Text('Moderation'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.emergency_rounded),
                selectedIcon: Icon(Icons.warning_amber_rounded),
                label: Text('Kill Switch'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_note_rounded),
                selectedIcon: Icon(Icons.auto_fix_high_rounded),
                label: Text('CMS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.app_settings_alt_rounded),
                selectedIcon: Icon(Icons.branding_watermark_rounded),
                label: Text('App Engine'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.psychology_alt_rounded),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: Text('AI Studio'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.support_agent_rounded),
                selectedIcon: Icon(Icons.mark_chat_read_rounded),
                label: Text('Destek'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AdminTheme.deep, Color(0xFF0B1F1B), Color(0xFF102B25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: KeyedSubtree(
                    key: ValueKey(index),
                    child: pages[index],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
