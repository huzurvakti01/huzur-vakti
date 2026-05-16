import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/errors/error_presenter.dart';
import '../core/theme/admin_theme.dart';
import '../services/auth_service.dart';
import '../services/functions_service.dart';
import '../shared/widgets/glass_panel.dart';

class GodModeStudioScreen extends StatefulWidget {
  const GodModeStudioScreen({super.key});

  @override
  State<GodModeStudioScreen> createState() => _GodModeStudioScreenState();
}

class _GodModeStudioScreenState extends State<GodModeStudioScreen> {
  final firestore = FirebaseFirestore.instance;
  final storage = FirebaseStorage.instance;

  final primaryColor = TextEditingController(text: '#0E7C66');
  final nativeAdAndroid = TextEditingController();
  final nativeAdIos = TextEditingController();
  final interstitialAndroid = TextEditingController();
  final interstitialIos = TextEditingController();
  final monthlyLabel = TextEditingController();
  final yearlyLabel = TextEditingController();
  final lifetimeLabel = TextEditingController();
  final discountLabel = TextEditingController();
  final translationSearch = TextEditingController();

  final flags = <String, bool>{
    'isAiEnabled': true,
    'isWomenCalendarVisible': true,
    'isSeferiModeActive': true,
    'isMediaCenterActive': true,
    'areAdsEnabled': true,
    'isNativeAdEnabled': true,
    'isInterstitialEnabled': true,
    'isPremiumPaywallEnabled': true,
    'isCommunityEnabled': true,
    'isKidsModeEnabled': true,
  };

  final translationKeys = <String>[
    'appName',
    'onboardingTitle',
    'smartSetupTitle',
    'authTitle',
    'authSubtitle',
    'dashboardStoriesTitle',
    'premiumTitle',
    'premiumDescription',
    'helpdeskTitle',
    'helpdeskSubtitle',
    'support',
    'settingsTitle',
    'quran',
    'toolsCompass',
    'assistantSupport',
    'calculationMethod',
  ];

  final languages = <String, String>{
    'tr': 'Türkçe',
    'en': 'English',
    'ar': 'العربية',
    'fr': 'Français',
    'ur': 'اردو',
    'id': 'Indonesia',
  };

  bool uploading = false;
  bool savingTheme = false;
  bool publishingFlags = false;
  bool savingRevenue = false;
  bool savingTranslations = false;
  String? selectedLogoPreviewUrl;

  DocumentReference<Map<String, dynamic>> get themeRef =>
      firestore.collection('app_settings').doc('theme');

  DocumentReference<Map<String, dynamic>> get monetizationRef =>
      firestore.collection('app_settings').doc('monetization');

  DocumentReference<Map<String, dynamic>> get translationOverrideRef =>
      firestore.collection('app_settings').doc('localization_override');

  @override
  void dispose() {
    primaryColor.dispose();
    nativeAdAndroid.dispose();
    nativeAdIos.dispose();
    interstitialAndroid.dispose();
    interstitialIos.dispose();
    monthlyLabel.dispose();
    yearlyLabel.dispose();
    lifetimeLabel.dispose();
    discountLabel.dispose();
    translationSearch.dispose();
    super.dispose();
  }

  void _hydrateTheme(Map<String, dynamic> data) {
    if (primaryColor.text == '#0E7C66' && (data['primaryColor'] ?? '').toString().isNotEmpty) {
      primaryColor.text = data['primaryColor'].toString();
    }

    selectedLogoPreviewUrl ??= (data['logoUrl'] ?? '').toString();
  }

  void _hydrateMonetization(Map<String, dynamic> data) {
    if (nativeAdAndroid.text.isEmpty) nativeAdAndroid.text = (data['admobNativeAndroidId'] ?? '').toString();
    if (nativeAdIos.text.isEmpty) nativeAdIos.text = (data['admobNativeIosId'] ?? '').toString();
    if (interstitialAndroid.text.isEmpty) interstitialAndroid.text = (data['admobInterstitialAndroidId'] ?? '').toString();
    if (interstitialIos.text.isEmpty) interstitialIos.text = (data['admobInterstitialIosId'] ?? '').toString();
    if (monthlyLabel.text.isEmpty) monthlyLabel.text = (data['premiumMonthlyLabel'] ?? 'Aylık Premium').toString();
    if (yearlyLabel.text.isEmpty) yearlyLabel.text = (data['premiumYearlyLabel'] ?? 'Yıllık Premium').toString();
    if (lifetimeLabel.text.isEmpty) lifetimeLabel.text = (data['premiumLifetimeLabel'] ?? 'Ömür Boyu Premium').toString();
    if (discountLabel.text.isEmpty) discountLabel.text = (data['premiumDiscountLabel'] ?? '%40 avantajlı').toString();
  }

  Future<void> _pickAndUploadLogo() async {
    setState(() => uploading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Logo dosyası okunamadı.');
      }

      if (bytes.length > 3 * 1024 * 1024) {
        throw const FormatException('Logo dosyası 3 MB altında olmalı.');
      }

      final path = 'brand_assets/logo_main_${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = storage.ref(path);

      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/png',
          customMetadata: {
            'uploadedBy': context.read<AuthService>().admin?.email ?? 'admin',
            'purpose': 'app_logo',
          },
        ),
      );

      final url = await ref.getDownloadURL();

      await themeRef.set({
        'logoUrl': url,
        'splashImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<AuthService>().admin?.email ?? 'admin',
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => selectedLogoPreviewUrl = url);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logo yüklendi ve mobil uygulamaya yayınlandı.')));
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _saveTheme() async {
    final color = primaryColor.text.trim();

    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      ErrorPresenter.snack(context, const FormatException('Hex renk #0F5132 formatında olmalı.'));
      return;
    }

    setState(() => savingTheme = true);

    try {
      await themeRef.set({
        'primaryColor': color,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<AuthService>().admin?.email ?? 'admin',
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tema rengi canlı olarak güncellendi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => savingTheme = false);
    }
  }

  Future<void> _publishFlags() async {
    setState(() => publishingFlags = true);

    try {
      await firestore.collection('app_settings').doc('feature_flags').set({
        ...flags,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<AuthService>().admin?.email ?? 'admin',
      }, SetOptions(merge: true));

      await context.read<FunctionsService>().publishRemoteConfigValues(flags);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature flags Remote Config’e yayınlandı.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => publishingFlags = false);
    }
  }

  Future<void> _saveMonetization() async {
    setState(() => savingRevenue = true);

    try {
      final payload = {
        'admobNativeAndroidId': nativeAdAndroid.text.trim(),
        'admobNativeIosId': nativeAdIos.text.trim(),
        'admobInterstitialAndroidId': interstitialAndroid.text.trim(),
        'admobInterstitialIosId': interstitialIos.text.trim(),
        'premiumMonthlyLabel': monthlyLabel.text.trim(),
        'premiumYearlyLabel': yearlyLabel.text.trim(),
        'premiumLifetimeLabel': lifetimeLabel.text.trim(),
        'premiumDiscountLabel': discountLabel.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<AuthService>().admin?.email ?? 'admin',
      };

      await monetizationRef.set(payload, SetOptions(merge: true));
      await context.read<FunctionsService>().publishRemoteConfigValues({
        'admobNativeAndroidId': nativeAdAndroid.text.trim(),
        'admobNativeIosId': nativeAdIos.text.trim(),
        'admobInterstitialAndroidId': interstitialAndroid.text.trim(),
        'admobInterstitialIosId': interstitialIos.text.trim(),
        'premiumMonthlyLabel': monthlyLabel.text.trim(),
        'premiumYearlyLabel': yearlyLabel.text.trim(),
        'premiumLifetimeLabel': lifetimeLabel.text.trim(),
        'premiumDiscountLabel': discountLabel.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reklam ve premium ayarları kaydedildi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => savingRevenue = false);
    }
  }

  Future<void> _saveTranslations(Map<String, TextEditingController> controllers) async {
    setState(() => savingTranslations = true);

    try {
      final override = <String, String>{};

      for (final entry in controllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          override[entry.key] = value;
        }
      }

      await translationOverrideRef.set({
        'localization_override': override,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': context.read<AuthService>().admin?.email ?? 'admin',
      }, SetOptions(merge: true));

      await themeRef.set({
        'localization_override': override,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canlı çeviri override haritası güncellendi.')));
      }
    } catch (error) {
      if (mounted) ErrorPresenter.snack(context, error);
    } finally {
      if (mounted) setState(() => savingTranslations = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: themeRef.snapshots(),
      builder: (context, themeSnapshot) {
        final themeData = themeSnapshot.data?.data() ?? {};
        _hydrateTheme(themeData);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: monetizationRef.snapshots(),
          builder: (context, monetizationSnapshot) {
            final monetizationData = monetizationSnapshot.data?.data() ?? {};
            _hydrateMonetization(monetizationData);

            return ListView(
              padding: const EdgeInsets.all(28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'App Engine & Brand Controller',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Logo, tema, şalterler, reklam gelirleri ve canlı dil override haritasını tek merkezden yönet.',
                            style: TextStyle(color: AdminTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: publishingFlags ? null : _publishFlags,
                      icon: publishingFlags
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Remote Config Yayınla'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;

                    final children = [
                      _brandEditor(themeData),
                      _featureMatrix(),
                      _monetizationEditor(),
                    ];

                    if (!wide) {
                      return Column(
                        children: children
                            .map((child) => Padding(padding: const EdgeInsets.only(bottom: 16), child: child))
                            .toList(),
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: children[0]),
                        const SizedBox(width: 16),
                        Expanded(child: children[1]),
                        const SizedBox(width: 16),
                        Expanded(child: children[2]),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _translationEditor(themeData),
              ],
            );
          },
        );
      },
    );
  }

  Widget _brandEditor(Map<String, dynamic> themeData) {
    final logoUrl = selectedLogoPreviewUrl ?? (themeData['logoUrl'] ?? '').toString();

    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.diamond_rounded,
            title: 'Marka ve Logo Editörü',
            subtitle: 'PNG logoyu Firebase Storage’a yükle; mobil uygulama anında yeni URL’i kullanır.',
          ),
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 148,
              height: 148,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.06),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(.12)),
              ),
              child: logoUrl.isEmpty
                  ? Image.asset('assets/images/logo_main.png')
                  : Image.network(
                      logoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset('assets/images/logo_main.png'),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: uploading ? null : _pickAndUploadLogo,
            icon: uploading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_file_rounded),
            label: const Text('PNG Logo Yükle'),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: primaryColor,
            decoration: const InputDecoration(
              labelText: 'Ana Renk Hex',
              helperText: 'Örn: #0F5132',
              prefixIcon: Icon(Icons.palette_rounded),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tryColor(primaryColor.text),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(.16)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: savingTheme ? null : _saveTheme,
                  icon: savingTheme
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_rounded),
                  label: const Text('Tema Rengini Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureMatrix() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.tune_rounded,
            title: 'Feature Control Matrix',
            subtitle: 'Aç/kapat değişiklikleri Remote Config publish ile mobil uygulamaya iner.',
          ),
          const SizedBox(height: 8),
          ...flags.entries.map(
            (entry) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: entry.value,
              onChanged: (value) => setState(() => flags[entry.key] = value),
              title: Text(_flagTitle(entry.key), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(entry.key, style: const TextStyle(color: AdminTheme.muted, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _monetizationEditor() {
    return GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.payments_rounded,
            title: 'Reklam ve Gelir Ayarlayıcı',
            subtitle: 'AdMob unit ID ve premium fiyat metinlerini canlı güncelle.',
          ),
          const SizedBox(height: 14),
          _field(nativeAdAndroid, 'AdMob Native Android ID', Icons.android_rounded),
          _field(nativeAdIos, 'AdMob Native iOS ID', Icons.apple_rounded),
          _field(interstitialAndroid, 'Interstitial Android ID', Icons.ad_units_rounded),
          _field(interstitialIos, 'Interstitial iOS ID', Icons.ad_units_rounded),
          const Divider(height: 28),
          _field(monthlyLabel, 'Aylık Paket Açıklaması', Icons.workspace_premium_rounded),
          _field(yearlyLabel, 'Yıllık Paket Açıklaması', Icons.calendar_month_rounded),
          _field(lifetimeLabel, 'Ömür Boyu Paket Açıklaması', Icons.all_inclusive_rounded),
          _field(discountLabel, 'İndirim / Kampanya Metni', Icons.local_offer_rounded),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: savingRevenue ? null : _saveMonetization,
            icon: savingRevenue
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_done_rounded),
            label: const Text('Gelir Ayarlarını Kaydet'),
          ),
        ],
      ),
    );
  }

  Widget _translationEditor(Map<String, dynamic> themeData) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: translationOverrideRef.snapshots(),
      builder: (context, snapshot) {
        final overrideDoc = snapshot.data?.data() ?? {};
        final override = Map<String, dynamic>.from(
          (overrideDoc['localization_override'] as Map?) ??
              (themeData['localization_override'] as Map?) ??
              const {},
        );

        final controllers = <String, TextEditingController>{};

        for (final lang in languages.keys) {
          for (final key in translationKeys) {
            final cloudKey = '$lang.$key';
            controllers[cloudKey] = TextEditingController(text: (override[cloudKey] ?? '').toString());
          }
        }

        final needle = translationSearch.text.trim().toLowerCase();
        final filteredKeys = translationKeys.where((key) {
          if (needle.isEmpty) return true;
          return key.toLowerCase().contains(needle);
        }).toList(growable: false);

        return GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionHeader(
                icon: Icons.translate_rounded,
                title: 'Küresel Dil ve Çeviri Düzenleyici',
                subtitle: '6 dil için localization_override haritası Firestore’a yazılır; mobil uygulama güncellemesiz değişir.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: translationSearch,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Anahtar ara',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(.06)),
                  columns: [
                    const DataColumn(label: Text('Key')),
                    ...languages.entries.map((entry) => DataColumn(label: Text(entry.value))),
                  ],
                  rows: filteredKeys.map((key) {
                    return DataRow(
                      cells: [
                        DataCell(SelectableText(key)),
                        ...languages.keys.map((lang) {
                          final cloudKey = '$lang.$key';
                          return DataCell(
                            SizedBox(
                              width: 220,
                              child: TextField(
                                controller: controllers[cloudKey],
                                decoration: InputDecoration(
                                  hintText: cloudKey,
                                  isDense: true,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: savingTranslations ? null : () => _saveTranslations(controllers),
                icon: savingTranslations
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_as_rounded),
                label: const Text('Çeviri Override Haritasını Kaydet'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  String _flagTitle(String key) {
    switch (key) {
      case 'isAiEnabled':
        return 'AI Asistan';
      case 'isWomenCalendarVisible':
        return 'Kadın Takvimi';
      case 'isSeferiModeActive':
        return 'Akıllı Seferi Mod';
      case 'isMediaCenterActive':
        return 'Medya Merkezi';
      case 'areAdsEnabled':
        return 'Tüm Reklamlar';
      case 'isNativeAdEnabled':
        return 'Native Ad';
      case 'isInterstitialEnabled':
        return 'Interstitial';
      case 'isPremiumPaywallEnabled':
        return 'Premium Paywall';
      case 'isCommunityEnabled':
        return 'Dua Topluluğu';
      case 'isKidsModeEnabled':
        return 'Çocuk Modu';
      default:
        return key;
    }
  }

  Color _tryColor(String value) {
    final clean = value.replaceAll('#', '').trim();

    if (clean.length != 6) {
      return AdminTheme.emerald;
    }

    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return AdminTheme.emerald;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AdminTheme.gold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: AdminTheme.muted)),
            ],
          ),
        ),
      ],
    );
  }
}
