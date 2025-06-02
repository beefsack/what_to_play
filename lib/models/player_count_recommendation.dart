enum PlayerCountRecommendation {
  best,
  recommended,
  notRecommended;

  @override
  String toString() {
    switch (this) {
      case PlayerCountRecommendation.best:
        return 'Best';
      case PlayerCountRecommendation.recommended:
        return 'Recommended';
      case PlayerCountRecommendation.notRecommended:
        return 'Not Recommended';
    }
  }
}

class PlayerCountData {
  final int playerCount;
  final PlayerCountRecommendation recommendation;

  PlayerCountData({required this.playerCount, required this.recommendation});

  Map<String, dynamic> toJson() {
    return {'playerCount': playerCount, 'recommendation': recommendation.name};
  }

  factory PlayerCountData.fromJson(Map<String, dynamic> json) {
    return PlayerCountData(
      playerCount: json['playerCount'] as int,
      recommendation: PlayerCountRecommendation.values.firstWhere(
        (e) => e.name == json['recommendation'],
      ),
    );
  }
}

class PlayerCountRecommendations {
  final Map<int, PlayerCountRecommendation> recommendations;

  PlayerCountRecommendations(this.recommendations);

  List<int> getBestPlayerCounts() {
    return recommendations.entries
        .where((entry) => entry.value == PlayerCountRecommendation.best)
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  List<int> getRecommendedPlayerCounts() {
    return recommendations.entries
        .where(
          (entry) =>
              entry.value == PlayerCountRecommendation.best ||
              entry.value == PlayerCountRecommendation.recommended,
        )
        .map((entry) => entry.key)
        .toList()
      ..sort();
  }

  String formatPlayerCountRange(List<int> counts) {
    if (counts.isEmpty) return '';

    final ranges = <String>[];
    int start = counts[0];
    int end = counts[0];

    for (int i = 1; i < counts.length; i++) {
      if (counts[i] == end + 1) {
        end = counts[i];
      } else {
        if (start == end) {
          ranges.add(start.toString());
        } else if (end == start + 1) {
          ranges.add('$start, $end');
        } else {
          ranges.add('$start-$end');
        }
        start = counts[i];
        end = counts[i];
      }
    }

    // Add the last range
    if (start == end) {
      ranges.add(start.toString());
    } else if (end == start + 1) {
      ranges.add('$start, $end');
    } else {
      ranges.add('$start-$end');
    }

    return ranges.join(', ');
  }

  String getBestWithText() {
    final bestCounts = getBestPlayerCounts();
    if (bestCounts.isEmpty) return '';
    return 'Best with ${formatPlayerCountRange(bestCounts)}';
  }

  String getRecommendedWithText() {
    final recommendedCounts = getRecommendedPlayerCounts();
    if (recommendedCounts.isEmpty) return '';
    return 'Recommended with ${formatPlayerCountRange(recommendedCounts)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendations': recommendations.map(
        (key, value) => MapEntry(key.toString(), value.name),
      ),
    };
  }

  factory PlayerCountRecommendations.fromJson(Map<String, dynamic> json) {
    final recommendationsMap = <int, PlayerCountRecommendation>{};
    final recommendations = json['recommendations'] as Map<String, dynamic>;

    for (final entry in recommendations.entries) {
      final playerCount = int.parse(entry.key);
      final recommendation = PlayerCountRecommendation.values.firstWhere(
        (e) => e.name == entry.value,
      );
      recommendationsMap[playerCount] = recommendation;
    }

    return PlayerCountRecommendations(recommendationsMap);
  }
}
