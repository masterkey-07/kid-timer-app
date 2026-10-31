import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/layout.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/features/parental/domain/app_info.dart';
import 'package:visual_time_counter/features/parental/domain/diagnostic_report.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The parent area (contracts/ui/07 §7.2), reached through the gate.
///
/// Keys: `parent.screen`, `parent.privacy`, `parent.licenses`,
/// `parent.credits`, `parent.source`, `parent.report`, `parent.help`,
/// `parent.noBrowser`.
class ParentAreaScreen extends ConsumerWidget {
  /// Creates the screen.
  const new({super.key = const Key('parent.screen')});

  /// Content width per size class (contracts/ui/00 §3).
  static const _mediumMaxWidth = 600.0;
  static const _expandedMaxWidth = 720.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.parentTitle)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = ScreenLayout.of(constraints.biggest);
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: layout.margin),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _maxWidth(layout)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(),
                      const Divider(),
                      _Row(
                        rowKey: 'parent.privacy',
                        title: l10n.parentPrivacy,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            unawaited(context.push(AppRoutes.parentPrivacy)),
                      ),
                      _Row(
                        rowKey: 'parent.licenses',
                        title: l10n.parentLicenses,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: l10n.appTitle,
                          applicationVersion:
                              '${AppInfo.version} (${AppInfo.build})',
                        ),
                      ),
                      _Row(
                        rowKey: 'parent.credits',
                        title: l10n.parentCredits,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            unawaited(context.push(AppRoutes.parentCredits)),
                      ),
                      _Row(
                        rowKey: 'parent.source',
                        title: l10n.parentSource,
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _confirmAndOpen(
                          context,
                          ref,
                          Uri.parse(AppInfo.sourceUrl),
                          message: l10n.parentOpenBrowserMessage(
                            AppInfo.sourceUrl,
                          ),
                        ),
                      ),
                      _Row(
                        rowKey: 'parent.report',
                        title: l10n.parentReport,
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _report(context, ref),
                      ),
                      _Row(
                        rowKey: 'parent.help',
                        title: l10n.parentHelp,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            unawaited(context.push(AppRoutes.batteryHelp)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static double _maxWidth(ScreenLayout layout) => switch (layout.sizeClass) {
    SizeClass.compact => double.infinity,
    SizeClass.medium => _mediumMaxWidth,
    SizeClass.expanded => _expandedMaxWidth,
  };

  /// Copies the diagnostic text, then offers the issue page.
  static Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final capabilities = await ref.read(alarmSchedulerProvider).capabilities();
    if (!context.mounted) return;

    final report = DiagnosticReport(
      version: AppInfo.version,
      build: AppInfo.build,
      platform: ref.read(appPlatformProvider),
      screenSize: MediaQuery.sizeOf(context),
      languageCode: Localizations.localeOf(context).languageCode,
      notifications: capabilities.notifications,
      exactAlarm: capabilities.exactAlarm,
    );
    await Clipboard.setData(ClipboardData(text: report.toText()));
    if (!context.mounted) return;

    await _confirmAndOpen(
      context,
      ref,
      Uri.parse(AppInfo.issuesUrl),
      message: l10n.parentReportMessage,
    );
  }

  /// Asks before leaving the app; tells the adult when nothing could open
  /// the link.
  static Future<void> _confirmAndOpen(
    BuildContext context,
    WidgetRef ref,
    Uri uri, {
    required String message,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isConfirmed = await showConfirmDialog(
      context,
      title: l10n.parentOpenBrowserConfirm,
      message: message,
      confirmLabel: l10n.parentOpenBrowserAction,
    );
    if (!isConfirmed) return;

    final isOpened = await ref.read(externalLinkProvider).open(uri);
    if (isOpened) return;
    messenger.showSnackBar(
      SnackBar(
        key: const Key('parent.noBrowser'),
        content: Text(l10n.parentNoBrowser),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.parentVersion(AppInfo.version, AppInfo.build),
            style: textTheme.titleMedium,
          ),
          Text(l10n.parentTagline),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const new({
    required this.rowKey,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final String rowKey;
  final String title;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(rowKey),
      title: Text(title),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
