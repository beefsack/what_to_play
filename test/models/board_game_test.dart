import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_play/models/board_game.dart';
import 'package:what_to_play/models/player_count_recommendation.dart';

void main() {
  group('BoardGame', () {
    late PlayerCountRecommendations playerCountRecommendations;

    setUp(() {
      playerCountRecommendations = PlayerCountRecommendations({
        2: PlayerCountRecommendation.recommended,
        3: PlayerCountRecommendation.best,
        4: PlayerCountRecommendation.best,
        5: PlayerCountRecommendation.recommended,
      });
    });

    test('should create a board game with all required fields', () {
      final game = BoardGame(
        id: '1',
        name: 'Catan',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        yearPublished: 1995,
        minPlayers: 3,
        maxPlayers: 4,
        playingTime: 75,
        minAge: 10,
        suggestedAge: 12,
        averageWeight: 2.5,
        playerCountRecommendations: playerCountRecommendations,
      );

      expect(game.id, '1');
      expect(game.name, 'Catan');
      expect(game.imageUrl, 'https://example.com/image.jpg');
      expect(game.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(game.yearPublished, 1995);
      expect(game.minPlayers, 3);
      expect(game.maxPlayers, 4);
      expect(game.playingTime, 75);
      expect(game.minAge, 10);
      expect(game.suggestedAge, 12);
      expect(game.averageWeight, 2.5);
      expect(game.playerCountRecommendations, playerCountRecommendations);
    });

    test('should create a board game without optional suggestedAge', () {
      final game = BoardGame(
        id: '1',
        name: 'Catan',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        yearPublished: 1995,
        minPlayers: 3,
        maxPlayers: 4,
        playingTime: 75,
        minAge: 10,
        averageWeight: 2.5,
        playerCountRecommendations: playerCountRecommendations,
      );

      expect(game.suggestedAge, isNull);
    });

    group('playerCountText', () {
      test('should return single player count when min equals max', () {
        final game = BoardGame(
          id: '1',
          name: 'Solo Game',
          imageUrl: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          yearPublished: 2020,
          minPlayers: 1,
          maxPlayers: 1,
          playingTime: 30,
          minAge: 8,
          averageWeight: 2.0,
          playerCountRecommendations: playerCountRecommendations,
        );

        expect(game.playerCountText, '1 players');
      });

      test('should return range when min and max are different', () {
        final game = BoardGame(
          id: '1',
          name: 'Party Game',
          imageUrl: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          yearPublished: 2020,
          minPlayers: 3,
          maxPlayers: 8,
          playingTime: 45,
          minAge: 10,
          averageWeight: 1.5,
          playerCountRecommendations: playerCountRecommendations,
        );

        expect(game.playerCountText, '3-8 players');
      });
    });

    test('should format playing time correctly', () {
      final game = BoardGame(
        id: '1',
        name: 'Test Game',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        yearPublished: 2020,
        minPlayers: 2,
        maxPlayers: 4,
        playingTime: 90,
        minAge: 12,
        averageWeight: 3.0,
        playerCountRecommendations: playerCountRecommendations,
      );

      expect(game.playingTimeText, '90 min');
    });

    group('ageText', () {
      test('should use suggestedAge when available', () {
        final game = BoardGame(
          id: '1',
          name: 'Test Game',
          imageUrl: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          yearPublished: 2020,
          minPlayers: 2,
          maxPlayers: 4,
          playingTime: 60,
          minAge: 8,
          suggestedAge: 12,
          averageWeight: 2.5,
          playerCountRecommendations: playerCountRecommendations,
        );

        expect(game.ageText, '12+');
      });

      test('should use minAge when suggestedAge is null', () {
        final game = BoardGame(
          id: '1',
          name: 'Test Game',
          imageUrl: 'https://example.com/image.jpg',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          yearPublished: 2020,
          minPlayers: 2,
          maxPlayers: 4,
          playingTime: 60,
          minAge: 10,
          averageWeight: 2.5,
          playerCountRecommendations: playerCountRecommendations,
        );

        expect(game.ageText, '10+');
      });
    });

    test('should format weight correctly', () {
      final game = BoardGame(
        id: '1',
        name: 'Test Game',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        yearPublished: 2020,
        minPlayers: 2,
        maxPlayers: 4,
        playingTime: 60,
        minAge: 10,
        averageWeight: 3.75,
        playerCountRecommendations: playerCountRecommendations,
      );

      expect(game.weightText, '3.8/5');
    });

    test('should format weight with one decimal place', () {
      final game = BoardGame(
        id: '1',
        name: 'Test Game',
        imageUrl: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        yearPublished: 2020,
        minPlayers: 2,
        maxPlayers: 4,
        playingTime: 60,
        minAge: 10,
        averageWeight: 2.0,
        playerCountRecommendations: playerCountRecommendations,
      );

      expect(game.weightText, '2.0/5');
    });
  });
}
