import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/app/widgets/confirm_dialog.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/application/settings_controller.dart';
import 'package:visual_time_counter/l10n/generated/app_localizations.dart';

/// The "Child mode" section of the settings (contracts/ui/06 §6.1): the
/// child lock switch and the screen pinning help (FR-032, FR-033).
///
/// Keys: `settings.childLock`, `settings.childLockPinning`.
class ChildModeSection extends ConsumerWidget {
  /// Creates the section.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isChildLockEnabled = ref.watch(
      appSettingsProvider.select((settings) => settings.childLockEnabled),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(
            l10n.settingsSectionChildMode,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SwitchListTile(
          key: const Key('settings.childLock'),
          title: Text(l10n.settingsChildLock),
          subtitle: Text(l10n.settingsChildLockDescription),
          value: isChildLockEnabled,
          onChanged: (isEnabled) =>
              unawaited(_setChildLock(context, ref, isEnabled: isEnabled)),
        ),
        ListTile(
          key: const Key('settings.childLockPinning'),
          title: Text(l10n.settingsChildLockPinning),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => unawaited(
            context.push<void>(
              AppRoutes.batteryHelpAt(BatteryHelpSection.pinning),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _setChildLock(
    BuildContext context,
    WidgetRef ref, {
    required bool isEnabled,
  }) async {
    final l10n = AppLocalizations.of(context);
    await ref
        .read(settingsControllerProvider)
        .setChildLockEnabled(
          isEnabled: isEnabled,
          confirmTurnOff: () => showConfirmDialog(
            context,
            title: l10n.settingsChildLockOffConfirmTitle,
            message: l10n.settingsChildLockOffConfirm,
            confirmLabel: l10n.settingsChildLockOffConfirmAction,
          ),
        );
  }
}
