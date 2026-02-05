import '../models/clipboard_item.dart';

class FuzzyMatch {
  final ClipboardItem item;
  final double score;
  final List<int> matchIndices;

  FuzzyMatch({
    required this.item,
    required this.score,
    required this.matchIndices,
  });
}

class FuzzySearch {
  /// Performs case-insensitive fuzzy search on a list of clipboard items.
  /// Returns results sorted by score (highest first), filtered to score > 0.
  static List<FuzzyMatch> search(String query, List<ClipboardItem> items) {
    if (query.isEmpty) {
      return items
          .map((item) => FuzzyMatch(item: item, score: 0, matchIndices: []))
          .toList();
    }

    final results = <FuzzyMatch>[];
    final queryLower = query.toLowerCase();

    for (final item in items) {
      final contentLower = item.content.toLowerCase();
      final matchResult = _fuzzyMatch(queryLower, contentLower);

      if (matchResult != null) {
        results.add(
          FuzzyMatch(
            item: item,
            score: matchResult['score'] as double,
            matchIndices: List<int>.from(matchResult['indices'] as List),
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Internal fuzzy matching logic.
  /// Returns null if no match; otherwise a map with 'score' and 'indices'.
  static Map<String, dynamic>? _fuzzyMatch(String query, String content) {
    final matchIndices = <int>[];
    var queryIdx = 0;
    var contentIdx = 0;
    var contiguousMatches = 0;
    var score = 0.0;

    while (queryIdx < query.length && contentIdx < content.length) {
      if (query[queryIdx] == content[contentIdx]) {
        matchIndices.add(contentIdx);
        queryIdx++;
        contiguousMatches++;
        // Boost score for contiguous matches
        score += 2.0;
        // Extra boost if match is early in string
        if (contentIdx < 10) score += 0.5;
      } else {
        contiguousMatches = 0;
      }
      contentIdx++;
    }

    // All query characters must be matched
    if (queryIdx < query.length) return null;

    // Boost for contiguous runs (adjacent characters)
    score += contiguousMatches.toDouble();

    // Penalize length difference
    score -= (content.length - query.length) * 0.1;

    return {
      'score': score,
      'indices': matchIndices,
    };
  }
}
