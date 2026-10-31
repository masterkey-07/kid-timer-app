import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

const _privacyAssetDirectory = 'assets/legal';
const _fallbackLanguage = 'en';
const Set<String> _bundledLanguages = {'pt', _fallbackLanguage};

/// The privacy policy for a language code, read from the bundled Markdown.
final FutureProviderFamily<String, String> privacyPolicyProvider =
    FutureProvider.family<String, String>((ref, languageCode) {
      final language = _bundledLanguages.contains(languageCode)
          ? languageCode
          : _fallbackLanguage;
      return rootBundle.loadString(
        '$_privacyAssetDirectory/privacy_$language.md',
      );
    });

/// The privacy policy as plain text (contracts/ui/07 §7.2); it never opens
/// the web.
///
/// Keys: `privacy.screen`, `privacy.error`.
class PrivacyScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key = const Key('privacy.screen')});

  /// Content width on wide screens (contracts/ui/00 §3).
  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final policy = ref.watch(privacyPolicyProvider(languageCode));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: SafeArea(
        child: policy.when(
          data: (text) => _Body(text: text),
          error: (_, _) => Center(
            child: Text(l10n.privacyLoadError, key: const Key('privacy.error')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final layout = ScreenLayout.of(MediaQuery.sizeOf(context));
    return SingleChildScrollView(
      padding: EdgeInsets.all(layout.margin),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: PrivacyScreen._maxWidth),
          child: Text(text),
        ),
      ),
    );
  }
}
