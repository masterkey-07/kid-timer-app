import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visual_time_counter/app/app.dart';
import 'package:visual_time_counter/bootstrap.dart';

Future<void> main() async {
  final overrides = await bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const KidTimerApp()));
}
