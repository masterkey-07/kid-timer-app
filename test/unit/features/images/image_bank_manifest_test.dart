import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Checks the committed library (research R9) rather than code: what
// tool/image_bank wrote and what a person approved in docs/assets-review.md.
const _bankDir = 'assets/images/bank';
const _reviewPath = 'docs/assets-review.md';
const _categories = ['hygiene', 'meal', 'play', 'rest', 'school', 'goingOut'];
const _minimumImages = 36;
const _minimumPerCategory = 6;
const _allowedLicenses = {'CC0-1.0', 'CC-BY-4.0', 'MIT', 'Apache-2.0'};
const _approved = 'approved';

void main() {
  final manifest = jsonDecode(
    File('$_bankDir/manifest.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final images = (manifest['images']! as List<Object?>)
      .cast<Map<String, Object?>>();

  test('has schema version 1', () {
    expect(manifest['schemaVersion'], 1);
  });

  test('has at least $_minimumImages images', () {
    expect(images.length, greaterThanOrEqualTo(_minimumImages));
  });

  test('has at least $_minimumPerCategory images in each category', () {
    for (final category in _categories) {
      final count = images.where((image) => image['category'] == category);
      expect(
        count.length,
        greaterThanOrEqualTo(_minimumPerCategory),
        reason: category,
      );
    }
  });

  test('uses only the six categories', () {
    for (final image in images) {
      expect(
        _categories,
        contains(image['category']),
        reason: '${image['id']}',
      );
    }
  });

  test('ids are unique and follow bank:<category>/<slug>', () {
    final ids = images.map((image) => image['id']! as String).toList();
    expect(ids.toSet().length, ids.length);
    for (final image in images) {
      expect(
        image['id'],
        'bank:${image['category']}/${_slugOf(image['file']! as String)}',
      );
    }
  });

  test('every image has non-empty pt and en names (FR-026)', () {
    for (final image in images) {
      final names = image['names']! as Map<String, Object?>;
      for (final locale in ['pt', 'en']) {
        expect(
          (names[locale] as String?)?.trim(),
          isNotEmpty,
          reason: '${image['id']} $locale',
        );
      }
    }
  });

  test('every image has an allowed license, an author and a source', () {
    for (final image in images) {
      expect(
        _allowedLicenses,
        contains(image['license']),
        reason: '${image['id']}',
      );
      expect(
        image['author'],
        isA<String>().having((a) => a, 'author', isNotEmpty),
      );
      expect(image['source'], startsWith('https://'), reason: '${image['id']}');
    }
  });

  test('every file exists under its category folder', () {
    for (final image in images) {
      final file = image['file']! as String;
      expect(file, startsWith('${image['category']}/'));
      expect(file, endsWith('.webp'));
      expect(File('$_bankDir/$file').existsSync(), isTrue, reason: file);
    }
  });

  test('pubspec bundles every category folder', () {
    // Flutter does not bundle subfolders of a listed asset folder.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final category in _categories) {
      expect(pubspec, contains('- $_bankDir/$category/'), reason: category);
    }
  });

  test('every image has an approved human review (Constitution II)', () {
    final reviews = _readImageReviews();
    final notApproved = [
      for (final image in images)
        if (!(reviews[image['id']]?.isApproved ?? false)) image['id'],
    ];
    expect(
      notApproved,
      isEmpty,
      reason:
          'Review these in $_reviewPath (reviewer, date and verdict '
          '"$_approved")',
    );
  });
}

String _slugOf(String file) =>
    file.split('/').last.replaceFirst(RegExp(r'\.webp$'), '');

/// Rows of the review table whose first cell is a `bank:` id.
Map<String, _Review> _readImageReviews() {
  final reviews = <String, _Review>{};
  for (final line in File(_reviewPath).readAsLinesSync()) {
    final cells = line.split('|').map((cell) => cell.trim()).toList();
    // | Asset | Label | Reviewer | Date | Verdict | Notes |
    if (cells.length < 7) continue;
    final id = cells[1].replaceAll('`', '');
    if (!id.startsWith('bank:')) continue;
    reviews[id] = _Review(
      reviewer: cells[3],
      date: cells[4],
      verdict: cells[5],
    );
  }
  return reviews;
}

class _Review {
  const new({
    required this.reviewer,
    required this.date,
    required this.verdict,
  });

  final String reviewer;
  final String date;
  final String verdict;

  bool get isApproved =>
      verdict == _approved &&
      _isFilled(reviewer) &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date);

  static bool _isFilled(String cell) => cell.isNotEmpty && cell != '—';
}
