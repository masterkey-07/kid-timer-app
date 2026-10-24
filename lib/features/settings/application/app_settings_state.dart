import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';

/// The settings loaded from storage at startup; bootstrap overrides it.
final restoredSettingsProvider = Provider<AppSettings>(
  (ref) => AppSettings.initial,
);

/// The current settings, seeded from storage.
final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

/// Owns the current [AppSettings] and writes every change to storage, so
/// features that change different fields never overwrite each other.
class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(restoredSettingsProvider);

  /// Applies [change] to the current settings and persists the result;
  /// storage errors propagate after the in-memory settings are updated.
  Future<void> update(AppSettings Function(AppSettings current) change) async {
    state = change(state);
    await ref.read(settingsRepositoryProvider).save(state);
  }
}
