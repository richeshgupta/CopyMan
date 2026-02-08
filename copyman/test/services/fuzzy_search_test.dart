import 'package:flutter_test/flutter_test.dart';

import 'package:copyman/models/clipboard_item.dart';
import 'package:copyman/services/fuzzy_search.dart';

ClipboardItem _item(int id, String content) => ClipboardItem(
      id: id,
      content: content,
      createdAt: 0,
      updatedAt: 0,
    );

void main() {
  final items = [
    _item(1, 'hello world'),
    _item(2, 'paste something'),
    _item(3, 'Copy text here'),
    _item(4, 'another clipboard entry'),
  ];

  group('FuzzySearch.search', () {
    test('empty query returns all items with score=0 and matchIndices=[]', () {
      final results = FuzzySearch.search('', items);
      expect(results.length, items.length);
      for (final r in results) {
        expect(r.score, 0.0);
        expect(r.matchIndices, isEmpty);
      }
    });

    test('exact match scores highest', () {
      final results = FuzzySearch.search('hello world', items);
      expect(results.isNotEmpty, isTrue);
      expect(results.first.item.content, 'hello world');
    });

    test('case-insensitive matching', () {
      final results = FuzzySearch.search('HELLO', items);
      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.item.content == 'hello world'), isTrue);
    });

    test('non-contiguous character matching ("ps" matches "paste")', () {
      final results = FuzzySearch.search('ps', items);
      expect(results.isNotEmpty, isTrue);
      expect(results.any((r) => r.item.content == 'paste something'), isTrue);
    });

    test('results sorted descending by score', () {
      final results = FuzzySearch.search('e', items);
      for (int i = 1; i < results.length; i++) {
        expect(results[i - 1].score >= results[i].score, isTrue);
      }
    });

    test('query with no matching chars returns empty list', () {
      final results = FuzzySearch.search('zzzzzzz', items);
      expect(results, isEmpty);
    });

    test('matchIndices are valid positions within content', () {
      final results = FuzzySearch.search('he', items);
      for (final r in results) {
        for (final idx in r.matchIndices) {
          expect(idx, greaterThanOrEqualTo(0));
          expect(idx, lessThan(r.item.content.length));
        }
      }
    });
  });
}
