import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';

/// A [LazyBox] kept in memory, for widget tests: Hive's lazy boxes need
/// real file IO, which never completes under the widget tester's fake
/// clock.
class InMemoryLazyBox<E> extends Fake implements LazyBox<E> {
  final _entries = <dynamic, E>{};

  @override
  Iterable<dynamic> get keys => _entries.keys.toList();

  @override
  int get length => _entries.length;

  @override
  bool get isEmpty => _entries.isEmpty;

  @override
  bool get isNotEmpty => _entries.isNotEmpty;

  @override
  bool containsKey(dynamic key) => _entries.containsKey(key);

  @override
  Future<E?> get(dynamic key, {E? defaultValue}) async =>
      _entries[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, E value) async => _entries[key] = value;

  @override
  Future<void> delete(dynamic key) async => _entries.remove(key);

  @override
  Future<void> flush() async {}
}
