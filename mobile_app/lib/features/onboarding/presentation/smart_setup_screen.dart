// zorunlu degisiklik testi
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/error_presenter.dart';
import '../../../core/models/country_profile.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/global_settings_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/dynamic_brand_logo.dart';
import '../../../shared/widgets/glass_card.dart';

class SmartSetupScreen extends StatefulWidget {
  const SmartSetupScreen({super.key});

  static const screenKey = 'smart_setup';

  @override
  State<SmartSetupScreen> createState() => _SmartSetupScreenState();
}

class _SmartSetupScreenState extends State<SmartSetupScreen> {
  Locale detectedLocale = const Locale('tr');
  CountryProfile detectedCountry = CountryProfile.fallback();
  bool detecting = true;
  bool manualOpen = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    final deviceLocale = ui.PlatformDispatcher.instance.locale;
    final locale = _supportedLocale(deviceLocale.languageCode);

    await context.setLocale(locale);

    CountryProfile country = _countryFromLocale(locale.languageCode);

    try {
      final pos = await context.read<LocationService>().currentPosition();
      country = CountryProfile.byCoordinates(pos.latitude, pos.longitude);
      await context.read<GlobalSettingsService>().setCountry(country);
    } catch (_) {
      await context.read<GlobalSettingsService>().setCountry(country);
    }

    if (!mounted) return;

    setState(() {
      detectedLocale = locale;
      detectedCountry = country;
      detecting = false;
    });
  }

  Locale _supportedLocale(String languageCode) {
    switch (languageCode) {
      case 'tr':
      case 'en':
      case 'ar':
      case 'fr':
      case 'ur':
      case 'id':
        return Locale(languageCode);
      default:
        return const Locale('en');
    }
  }

  CountryProfile _countryFromLocale(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return CountryProfile.byCode('TR');
      case 'ar':
        return CountryProfile.byCode('SA');
      case 'ur':
        return CountryProfile.byCode('PK');
      case 'id':
        return CountryProfile.byCode('ID');
      case 'fr':
        return CountryProfile.byCode('FR');
      default:
        return CountryProfile.byCode('US');
    }
  }

  Future<void> _confirm() async {
    setState(() => saving = true);

    try {
      await context.read<GlobalSettingsService>().completeLanguageCountrySetup(
            country: detectedCountry,
          );

      if (!mounted) return;

      final signedIn = context.read<AuthService>().user != null;
      context.go(signedIn ? '/' : '/auth');
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _openManual() {
    setState(() => manualOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final direction = Directionality.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.nightBlue, AppTheme.deepEmerald, Color(0xFF071B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: manualOpen
                ? _ManualSetupPane(
                    initialLocale: detectedLocale,
                    initialCountry: detectedCountry,
                    onChanged: (locale, country) {
                      setState(() {
                        detectedLocale = locale;
                        detectedCountry = country;
                      });
                    },
                  )
                : ListView(
                    key: const ValueKey('auto-detect'),
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
                    children: [
                      const SizedBox(height: 22),
                      const DynamicBrandLogo(width: 120),
                      const SizedBox(height: 18),
                      Text(
                        AppStrings.smartSetupTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        AppStrings.smartSetupSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, height: 1.45),
                      ),
                      const SizedBox(height: 22),
                      GlassCard(
                        opacity: .18,
                        blur: 24,
                        child: detecting
                            ? const SizedBox(
                                height: 220,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 16),
                                      Text(AppStrings.smartSetupDetecting, style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text('🌍', style: TextStyle(fontSize: 36)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              AppStrings.detectedRegion,
                                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                                            ),
                                            Text(
                                              '${detectedCountry.flag} ${detectedCountry.label(context.locale.languageCode)}',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 30),
                                  Row(
                                    children: [
                                      const Text('🗣️', style: TextStyle(fontSize: 36)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              AppStrings.detectedLanguage,
                                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                                            ),
                                            Text(
                                              _languageName(detectedLocale.languageCode),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        direction == TextDirection.rtl ? 'RTL' : 'LTR',
                                        style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w900),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '${detectedCountry.method.title} • ${detectedCountry.method.subtitle}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: detecting || saving ? null : _confirm,
                        icon: saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.check_circle_rounded),
                        label: const Text(AppStrings.confirmAndContinue),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: detecting ? null : _openManual,
                        icon: const Icon(Icons.tune_rounded),
                        label: const Text(AppStrings.changeRegionLanguage),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        AppStrings.smartSetupAutoFallback,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  String _languageName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      case 'fr':
        return 'Français';
      case 'ur':
        return 'اردو';
      case 'id':
        return 'Indonesia';
      default:
        return 'English';
    }
  }
}

class _ManualSetupPane extends StatefulWidget {
  final Locale initialLocale;
  final CountryProfile initialCountry;
  final void Function(Locale locale, CountryProfile country) onChanged;

  const _ManualSetupPane({
    required this.initialLocale,
    required this.initialCountry,
    required this.onChanged,
  });

  @override
  State<_ManualSetupPane> createState() => _ManualSetupPaneState();
}

class _ManualSetupPaneState extends State<_ManualSetupPane> {
  final search = TextEditingController();
  late Locale selectedLocale;
  late CountryProfile selectedCountry;
  bool saving = false;

  static const languages = [
    _LanguageChoice(Locale('tr'), '🇹🇷', 'Türkçe'),
    _LanguageChoice(Locale('en'), '🇬🇧', 'English'),
    _LanguageChoice(Locale('ar'), '🇸🇦', 'العربية'),
    _LanguageChoice(Locale('fr'), '🇫🇷', 'Français'),
    _LanguageChoice(Locale('ur'), '🇵🇰', 'اردو'),
    _LanguageChoice(Locale('id'), '🇮🇩', 'Indonesia'),
  ];

  @override
  void initState() {
    super.initState();
    selectedLocale = widget.initialLocale;
    selectedCountry = widget.initialCountry;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(Locale locale) async {
    await context.setLocale(locale);
    setState(() => selectedLocale = locale);
    widget.onChanged(selectedLocale, selectedCountry);
  }

  Future<void> _selectCountry(CountryProfile country) async {
    await context.read<GlobalSettingsService>().setCountry(country);
    setState(() => selectedCountry = country);
    widget.onChanged(selectedLocale, selectedCountry);
  }

  Future<void> _confirm() async {
    setState(() => saving = true);

    try {
      await context.read<GlobalSettingsService>().completeLanguageCountrySetup(
            country: selectedCountry,
          );

      if (!mounted) return;

      final signedIn = context.read<AuthService>().user != null;
      context.go(signedIn ? '/' : '/auth');
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final needle = search.text.trim().toLowerCase();
    final countries = CountryProfile.all.where((country) {
      final label = country.label(context.locale.languageCode).toLowerCase();
      return needle.isEmpty ||
          label.contains(needle) ||
          country.nameEn.toLowerCase().contains(needle) ||
          country.nameTr.toLowerCase().contains(needle) ||
          country.code.toLowerCase().contains(needle);
    }).toList(growable: false);

    return ListView(
      key: const ValueKey('manual-setup'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 28),
      children: [
        Text(
          AppStrings.smartSetupManualSelection,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          opacity: .18,
          blur: 24,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: languages.map((language) {
              final selected = selectedLocale.languageCode == language.locale.languageCode;
              return ChoiceChip(
                selected: selected,
                label: Text('${language.flag} ${language.name}'),
                onSelected: (_) => _selectLanguage(language.locale),
              );
            }).toList(),
          ),
        ),
        GlassCard(
          opacity: .18,
          blur: 24,
          child: Column(
            children: [
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: AppStrings.searchCountry,
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: ListView.separated(
                  itemCount: countries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    final selected = selectedCountry.code == country.code;

                    return ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      tileColor: selected ? AppTheme.gold.withOpacity(.20) : Colors.white.withOpacity(.07),
                      leading: Text(country.flag, style: const TextStyle(fontSize: 28)),
                      title: Text(
                        country.label(context.locale.languageCode),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        '${country.code} • ${country.method.title}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: selected ? const Icon(Icons.check_rounded, color: AppTheme.gold) : null,
                      onTap: () => _selectCountry(country),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: saving ? null : _confirm,
          icon: saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_rounded),
          label: const Text(AppStrings.confirmAndContinue),
        ),
      ],
    );
  }
}

class _LanguageChoice {
  final Locale locale;
  final String flag;
  final String name;

  const _LanguageChoice(this.locale, this.flag, this.name);
}
