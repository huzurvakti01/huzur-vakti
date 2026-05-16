import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../services/auth_service.dart';
import '../shared/widgets/glass_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    try {
      await context.read<AuthService>().login(
            email: email.text.trim(),
            password: password.text,
          );
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF0E7C66), AdminTheme.deep],
            center: Alignment.topLeft,
            radius: 1.1,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: GlassPanel(
              padding: const EdgeInsets.all(34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_main.png',
                    width: 128,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'God Mode Admin',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Huzur Vakti mutlak yönetim paneli',
                    style: TextStyle(color: AdminTheme.muted),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.email_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: auth.loading ? null : _login,
                    icon: auth.loading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login_rounded),
                    label: const Text('God Mode Giriş'),
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
