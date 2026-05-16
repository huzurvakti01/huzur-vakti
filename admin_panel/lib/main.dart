import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/admin_theme.dart';
import 'firebase_options.dart';
import 'screens/app_shell.dart';
import 'services/ai_autopilot_service.dart';
import 'services/auth_service.dart';
import 'services/cms_service.dart';
import 'services/functions_service.dart';
import 'services/kill_switch_service.dart';
import 'services/moderation_service.dart';
import 'services/support_ticket_service.dart';
import 'services/user_matrix_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const GodModeAdminApp());
}

class GodModeAdminApp extends StatelessWidget {
  const GodModeAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FunctionsService()),
        ChangeNotifierProvider(
          create: (context) => AuthService(
            functions: context.read<FunctionsService>(),
          )..init(),
        ),
        Provider(
          create: (context) => UserMatrixService(
            functions: context.read<FunctionsService>(),
          ),
        ),
        Provider(create: (_) => ModerationService()),
        Provider(
          create: (context) => KillSwitchService(
            functions: context.read<FunctionsService>(),
          ),
        ),
        Provider(create: (_) => CmsService()),
        Provider(create: (_) => SupportTicketService()),
        Provider(create: (context) => AiAutopilotService(functions: context.read<FunctionsService>())),
      ],
      child: MaterialApp(
        title: 'Huzur Vakti God Mode',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.dark(),
        home: const AppShell(),
      ),
    );
  }
}
