import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/services/ads/ad_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dynamic_brand_logo.dart';
import '../../../shared/widgets/glass_card.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  static const screenKey = 'auth';

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();

      if (context.mounted && !context.read<PurchaseService>().isPremium) {
        context.read<AdService>().trackCompletedAction(
              context: context,
              screenKey: AppStrings.profileBackupAdScreen,
            );
      }

      if (context.mounted) context.go('/');
    } on AppException catch (error) {
      if (error.code == 'already_signed_in') {
        if (context.mounted) context.go('/');
        return;
      }

      if (context.mounted) ErrorPresenter.showSnackBar(context, error);
    } catch (error) {
      if (context.mounted) ErrorPresenter.showSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF061A17),
              Color(0xFF0E7C66),
              Color(0xFFE8D49B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(22),
                children: [
                  const DynamicBrandLogo(width: 120),
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppStrings.authTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          AppStrings.authSubtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 26),
                        FilledButton.icon(
                          onPressed: auth.loading
                              ? null
                              : () => _run(
                                    context,
                                    () => context.read<AuthService>().signInWithGoogle(),
                                  ),
                          icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                          label: const Text(AppStrings.signInWithGoogle),
                        ),
                        if (Platform.isIOS || Platform.isMacOS) ...[
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: auth.loading
                                ? null
                                : () => _run(
                                      context,
                                      () => context.read<AuthService>().signInWithApple(),
                                    ),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.apple_rounded),
                            label: const Text(AppStrings.signInWithApple),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: auth.loading
                              ? null
                              : () => _run(
                                    context,
                                    () => context.read<AuthService>().continueAsGuest(),
                                  ),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text(AppStrings.continueAsGuest),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          AppStrings.guestSyncWarning,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                        if (auth.loading) ...[
                          const SizedBox(height: 18),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      ],
                    ),
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
