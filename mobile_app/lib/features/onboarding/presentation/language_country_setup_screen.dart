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
import '../../../shared/widgets/glass_card.dart';

class LanguageCountrySetupScreen extends StatefulWidget {
  const LanguageCountrySetupScreen({super.key});

  static const screenKey = 'language_country_setup';

  @override
  State<LanguageCountrySetupScreen> createState() => _LanguageCountrySetupScreenState();
}

class _LanguageCountrySetupScreenState extends State<LanguageCountrySetupScreen> {
  final search = TextEditingController();
  Locale selectedLocale = const Locale('tr');
  CountryProfile? selectedCountry;
  bool locating = false;
  bool saving = false;

  static const languages = [
    _LanguageOption(locale: Locale('tr'), flag: '🇹🇷', name: 'Türkçe'),
    _LanguageOption(locale: Locale('en'), flag: '🇬🇧', name: 'English'),
    _LanguageOption(locale: Locale('ar'), flag: '🇸🇦', name: 'العربية'),
    _LanguageOption(locale: Locale('fr'), flag: '🇫🇷', name: 'Français'),
    _LanguageOption(locale: Locale('ur'), flag: '🇵🇰', name: 'اردو'),
    _LanguageOption(locale: Locale('id'), flag: '🇮🇩', name: 'Indonesia'),
  ];

  @override
  void initState() {
    super.initState();

    selectedLocale = context.locale;
    final settings = context.read<GlobalSettingsService>();
    selectedCountry = settings.country;
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> _selectLanguage(Locale locale) async {
    await context.setLocale(locale);
    if (mounted) {
      setState(() => selectedLocale = locale);
    }
  }

  Future<void> _detectLocation() async {
    setState(() => locating = true);

    try {
      final pos = await context.read<LocationService>().currentPosition();
      final country = await context.read<GlobalSettingsService>().autoSelectCountry(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );

      if (!mounted) return;

      setState(() => selectedCountry = country);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Text('${AppStrings.countryDetected} ${country.flag} ${country.label(context.locale.languageCode)}'),
        ),
      );
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> _continue() async {
    final country = selectedCountry;

    if (country == null) {
      ErrorPresenter.showSnackBar(context,  Exception(AppStrings.countryRequired));
      return;
    }

    setState(() => saving = true);

    try {
      await context.read<GlobalSettingsService>().completeLanguageCountrySetup(
            country: country,
          );

      if (!mounted) return;

      final signedIn = context.read<AuthService>().user != null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: const Text(AppStrings.setupSaved),
        ),
      );

      context.go(signedIn ? '/' : '/auth');
    } catch (error) {
      if (mounted) ErrorPresenter.showSnackBar(context, error);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsService>();
    final needle = search.text.trim().toLowerCase();
    final countries = CountryProfile.all.where((country) {
      final local = country.label(context.locale.languageCode).toLowerCase();
      return needle.isEmpty ||
          local.contains(needle) ||
          country.nameEn.toLowerCase().contains(needle) ||
          country.nameTr.toLowerCase().contains(needle) ||
          country.code.toLowerCase().contains(needle);
    }).toList(growable: false);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.deepEmerald, Color(0xFF071B22), Color(0xFF102B25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              const SizedBox(height: 10),
              const Icon(Icons.language_rounded, color: AppTheme.gold, size: 64),
              const SizedBox(height: 14),
              Text(
                AppStrings.languageCountrySetupTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                AppStrings.languageCountrySetupSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.chooseLanguage,
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.9,
                      ),
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        final selected = selectedLocale.languageCode == language.locale.languageCode;

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _selectLanguage(language.locale),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.gold.withOpacity(.22) : Colors.white.withOpacity(.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected ? AppTheme.gold : Colors.white.withOpacity(.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(language.flag, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    language.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.gold),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppStrings.chooseCountry} • ${settings.method.title}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: search,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: AppStrings.searchCountry,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: search.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  search.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 320,
                      child: ListView.separated(
                        itemCount: countries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final country = countries[index];
                          final selected = selectedCountry?.code == country.code;

                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            tileColor: selected ? AppTheme.emerald.withOpacity(.26) : Colors.white.withOpacity(.07),
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
                            onTap: () async {
                              await context.read<GlobalSettingsService>().setCountry(country);
                              if (mounted) setState(() => selectedCountry = country);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: locating ? null : _detectLocation,
                      icon: locating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded),
                      label: const Text(AppStrings.detectMyLocation),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: saving ? null : _continue,
                icon: saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_forward_rounded),
                label: const Text(AppStrings.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  final Locale locale;
  final String flag;
  final String name;

  const _LanguageOption({
    required this.locale,
    required this.flag,
    required this.name,
  });
}
