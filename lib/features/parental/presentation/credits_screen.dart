import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/parental/application/credits.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// Authors, licenses and sources of the images and sounds, read from the
/// bundled manifests (contracts/ui/07 §7.2).
///
/// Keys: `credits.screen`, `credits.error`, `credits.images`,
/// `credits.sounds`.
class CreditsScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key = const Key('credits.screen')});

  /// Content width on wide screens (contracts/ui/00 §3).
  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final credits = ref.watch(creditsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.creditsTitle)),
      body: SafeArea(
        child: credits.when(
          data: (credits) => _Content(credits: credits),
          error: (_, _) => const _LoadError(),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const new({required this.credits});

  final Credits credits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final layout = ScreenLayout.of(MediaQuery.sizeOf(context));
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.margin),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: CreditsScreen._maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(l10n.creditsImages, style: titleStyle),
              ),
              Column(
                key: const Key('credits.images'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final image in credits.images)
                    _ImageCredit(image: image, languageCode: languageCode),
                ],
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(l10n.creditsSounds, style: titleStyle),
              ),
              Text(credits.soundsLicenseText, key: const Key('credits.sounds')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageCredit extends StatelessWidget {
  const new({required this.image, required this.languageCode});

  final BankImageAsset image;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(image.labels[languageCode] ?? image.labels['en']!),
      subtitle: Text(
        '${l10n.creditsAuthorLicense(image.author, image.license)}\n'
        '${image.source}',
      ),
      isThreeLine: true,
    );
  }
}

/// "Credits could not be loaded", with the assets' `LICENSES.md` instead.
class _LoadError extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final fallback = ref.watch(creditsFallbackTextProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.parentCreditsError, key: const Key('credits.error')),
          if (fallback.hasValue) Text(fallback.requireValue),
        ],
      ),
    );
  }
}
