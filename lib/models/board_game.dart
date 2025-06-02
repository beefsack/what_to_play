import 'player_count_recommendation.dart';

class BoardGame {
  final String id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl;
  final int yearPublished;
  final int minPlayers;
  final int maxPlayers;
  final int playingTime;
  final int minAge;
  final int? suggestedAge;
  final double averageWeight;
  final PlayerCountRecommendations playerCountRecommendations;

  BoardGame({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.yearPublished,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playingTime,
    required this.minAge,
    this.suggestedAge,
    required this.averageWeight,
    required this.playerCountRecommendations,
  });

  String get playerCountText {
    if (minPlayers == maxPlayers) {
      return '$minPlayers players';
    }
    return '$minPlayers-$maxPlayers players';
  }

  String get playingTimeText {
    return '$playingTime min';
  }

  String get ageText {
    final age = suggestedAge ?? minAge;
    return '$age+';
  }

  String get weightText {
    return '${averageWeight.toStringAsFixed(1)}/5';
  }
}
