import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/app/router.dart';
import 'package:visual_time_counter/core/clock/clock_provider.dart';
import 'package:visual_time_counter/core/domain/timer_config.dart';
import 'package:visual_time_counter/core/domain/visual_source.dart';
import 'package:visual_time_counter/core/platform/fullscreen/fullscreen_port.dart';
import 'package:visual_time_counter/core/platform/lifecycle/app_lifecycle_port.dart';
import 'package:visual_time_counter/core/platform/providers.dart';
import 'package:visual_time_counter/core/platform/wakelock/wakelock_port.dart';
import 'package:visual_time_counter/core/timer_engine/timer_session.dart';
import 'package:visual_time_counter/features/images/application/image_library.dart';
import 'package:visual_time_counter/features/images/data/bank_manifest_loader.dart';
import 'package:visual_time_counter/features/images/data/user_image_repository.dart';
import 'package:visual_time_counter/features/images/domain/image_asset.dart';
import 'package:visual_time_counter/features/settings/application/app_settings_state.dart';
import 'package:visual_time_counter/features/settings/data/settings_repository.dart';
import 'package:visual_time_counter/features/settings/domain/app_settings.dart';
import 'package:visual_time_counter/features/timer/application/active_session.dart';
import 'package:visual_time_counter/features/timer/data/session_repository.dart';

import 'fakes/fake_alarm_scheduler.dart';
import 'fakes/fake_audio.dart';
import 'fakes/fake_external_link.dart';
import 'fakes/fake_fullscreen.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_image_picker.dart';
import 'fakes/fake_image_processor.dart';
import 'fakes/fake_lifecycle.dart';
import 'fakes/fake_system_settings.dart';
import 'fakes/fake_wakelock.dart';
import 'in_memory_lazy_box.dart';
import 'pump_app.dart';

/// The instant every app-level test starts at.
final testNow = DateTime.utc(2026, 10, 23, 12);

var _boxCount = 0;

/// Fakes for every port, in-memory storage and a controllable clock: what
/// bootstrap provides in the real app.
class TestAppDependencies {
  new _(
    this._sessionBox,
    this._settingsBox,
    this.userImagesMeta,
    this.presets,
    this.bankImages,
    Clock? clock,
  ) {
    this.clock = clock ?? Clock(() => now);
    alarms = FakeAlarmScheduler(clock: this.clock);
    sessionRepository = SessionRepository(_sessionBox);
    settingsRepository = SettingsRepository(_settingsBox);
  }

  /// Opens empty in-memory boxes. With [clock] (e.g. the real one) [now]
  /// is ignored.
  static Future<TestAppDependencies> create({Clock? clock}) async {
    final id = _boxCount++;
    return TestAppDependencies._(
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_session_$id',
        bytes: Uint8List(0),
      ),
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_settings_$id',
        bytes: Uint8List(0),
      ),
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_user_images_meta_$id',
        bytes: Uint8List(0),
      ),
      await Hive.openBox<Map<dynamic, dynamic>>(
        'test_presets_$id',
        bytes: Uint8List(0),
      ),
      await _loadBankImages(),
      clock,
    );
  }

  final Box<Map<dynamic, dynamic>> _sessionBox;
  final Box<Map<dynamic, dynamic>> _settingsBox;

  /// Own image metadata.
  final Box<Map<dynamic, dynamic>> userImagesMeta;

  /// Own image bytes.
  final userImageBytes = InMemoryLazyBox<Uint8List>();

  /// Presets, as raw documents until the presets feature (US5).
  final Box<Map<dynamic, dynamic>> presets;

  /// What the clock reads; tests move it forward.
  DateTime now = testNow;

  late final Clock clock;
  late final FakeAlarmScheduler alarms;
  late final SessionRepository sessionRepository;
  late final SettingsRepository settingsRepository;

  /// The audio fake; a test may swap it before building the overrides.
  FakeAudio audio = FakeAudio();
  final haptics = FakeHaptics();
  final wakeLock = FakeWakeLock();

  /// A real wakelock to use instead of [wakeLock] (integration tests).
  WakeLockPort? wakeLockOverride;
  final fullscreen = FakeFullscreen();

  /// A real full screen to use instead of [fullscreen] (integration tests).
  FullscreenPort? fullscreenOverride;
  final lifecycle = FakeLifecycle();

  /// A real lifecycle to use instead of [lifecycle] (integration tests).
  AppLifecyclePort? lifecycleOverride;
  final systemSettings = FakeSystemSettings();
  final imagePicker = FakeImagePicker();
  final imageProcessor = FakeImageProcessor();

  /// The library, read from the committed manifest.
  List<BankImageAsset> bankImages;

  /// What decoding a picked image for the frame screen yields; null makes
  /// it fail as for a file that cannot be opened.
  ui.Image? pickedPreview;

  var _nextImageId = 0;

  /// The platform the app believes it runs on; tests may change it.
  AppPlatform platform = AppPlatform.android;

  /// The overrides for a `ProviderScope` restoring [session] and
  /// [settings].
  List<Override> overrides({
    TimerSession? session,
    AppSettings settings = AppSettings.initial,
    bool Function(String presetId)? presetExists,
  }) => [
    clockProvider.overrideWithValue(clock),
    sessionRepositoryProvider.overrideWithValue(sessionRepository),
    settingsRepositoryProvider.overrideWithValue(settingsRepository),
    restoredSessionProvider.overrideWithValue(session),
    restoredSettingsProvider.overrideWithValue(settings),
    presetExistsProvider.overrideWithValue(presetExists ?? (_) => false),
    ...imageOverrides(),
    ...portOverrides(),
  ];

  /// The library, own image storage and processing.
  List<Override> imageOverrides() => [
    bankImagesProvider.overrideWith((ref) => bankImages),
    userImageStorageProvider.overrideWithValue(
      UserImageStorage(
        meta: userImagesMeta,
        bytes: userImageBytes,
        presets: presets,
      ),
    ),
    userImageIdGeneratorProvider.overrideWithValue(
      () => 'image-${_nextImageId++}',
    ),
    imageProcessorProvider.overrideWithValue(imageProcessor),
    imagePreviewDecoderProvider.overrideWithValue((bytes) async {
      final preview = pickedPreview;
      if (preview == null) throw const FormatException('Cannot decode');
      return preview;
    }),
  ];

  /// The fake platform ports alone, for tests that use the real storage
  /// and startup path.
  List<Override> portOverrides() => [
    appPlatformProvider.overrideWithValue(platform),
    alarmSchedulerProvider.overrideWithValue(alarms),
    audioProvider.overrideWithValue(audio),
    hapticsProvider.overrideWithValue(haptics),
    wakeLockProvider.overrideWithValue(wakeLockOverride ?? wakeLock),
    fullscreenProvider.overrideWithValue(fullscreenOverride ?? fullscreen),
    appLifecycleProvider.overrideWithValue(lifecycleOverride ?? lifecycle),
    imagePickerProvider.overrideWithValue(imagePicker),
    systemSettingsProvider.overrideWithValue(systemSettings),
    externalLinkProvider.overrideWithValue(FakeExternalLink()),
  ];

  /// Stores [count] own images, oldest first, as if added earlier.
  Future<List<UserImageAsset>> seedUserImages(int count) async {
    final images = [
      for (var index = 0; index < count; index++)
        UserImageAsset(
          id: 'seed-$index',
          label: 'Image $index',
          createdAt: testNow.add(Duration(seconds: index)),
          width: 1024,
          height: 1024,
          byteLength: _seedJpeg.length,
        ),
    ];
    for (final image in images) {
      await userImageBytes.put(image.id, _seedJpeg);
      await userImagesMeta.put(image.id, image.toJson());
    }
    return images;
  }

  /// Stores a preset document named [name] showing [visual].
  Future<void> seedPreset(String id, String name, VisualSource visual) =>
      presets.put(id, {
        'schemaVersion': 1,
        'id': id,
        'name': name,
        'order': presets.length,
        'isExample': false,
        'favorite': false,
        'config': TimerConfig.defaults.copyWith(visual: visual).toJson(),
        'createdAt': testNow.toIso8601String(),
        'updatedAt': testNow.toIso8601String(),
      });

  /// Makes every later session write fail, as a full disk would.
  Future<void> breakSessionStorage() => _sessionBox.close();

  /// Makes every later settings write fail, as a full disk would.
  Future<void> breakSettingsStorage() => _settingsBox.close();

  /// Closes the boxes.
  Future<void> dispose() async {
    await lifecycle.dispose();
    if (_sessionBox.isOpen) await _sessionBox.close();
    if (_settingsBox.isOpen) await _settingsBox.close();
    await userImagesMeta.close();
    await presets.close();
  }
}

final _seedJpeg = Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]);

const _bankManifestAsset = 'assets/images/bank/manifest.json';

Future<List<BankImageAsset>>? _bankImages;

/// The committed library manifest, parsed once. Read from the asset bundle
/// so integration tests find it on a device as well as on the host.
Future<List<BankImageAsset>> _loadBankImages() => _bankImages ??= rootBundle
    .loadString(_bankManifestAsset)
    .then(BankManifestLoader.parse);

extension PumpKidTimerApp on WidgetTester {
  /// Pumps the whole app (router included) over [dependencies], in
  /// [locale] and sized as [screen]. Does not settle: the countdown dial
  /// repaints on every frame.
  Future<void> pumpKidTimerApp(
    TestAppDependencies dependencies, {
    TimerSession? session,
    AppSettings settings = AppSettings.initial,
    ScreenClass screen = ScreenClass.compact,
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async {
    view
      ..physicalSize = screen.size
      ..devicePixelRatio = 1;
    addTearDown(view.reset);
    platformDispatcher
      ..localesTestValue = [locale]
      ..textScaleFactorTestValue = textScale;
    addTearDown(platformDispatcher.clearAllTestValues);

    await pumpWidget(
      ProviderScope(
        overrides: dependencies.overrides(session: session, settings: settings),
        child: const KidTimerApp(),
      ),
    );
    await pump();
  }

  /// The text shown by the widget with [key].
  String textOf(String key) => widget<Text>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
  ).data!;
}
