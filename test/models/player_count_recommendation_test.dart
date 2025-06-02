import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_play/models/player_count_recommendation.dart';

void main() {
  group('PlayerCountRecommendation', () {
    test('should have correct string representations', () {
      expect(PlayerCountRecommendation.best.toString(), 'Best');
      expect(PlayerCountRecommendation.recommended.toString(), 'Recommended');
      expect(
        PlayerCountRecommendation.notRecommended.toString(),
        'Not Recommended',
      );
    });
  });

  group('PlayerCountData', () {
    test('should create with player count and recommendation', () {
      final data = PlayerCountData(
        playerCount: 4,
        recommendation: PlayerCountRecommendation.best,
      );

      expect(data.playerCount, 4);
      expect(data.recommendation, PlayerCountRecommendation.best);
    });

    test('should convert to JSON correctly', () {
      final data = PlayerCountData(
        playerCount: 3,
        recommendation: PlayerCountRecommendation.recommended,
      );

      final json = data.toJson();

      expect(json, {'playerCount': 3, 'recommendation': 'recommended'});
    });

    test('should create from JSON correctly', () {
      final json = {'playerCount': 5, 'recommendation': 'best'};

      final data = PlayerCountData.fromJson(json);

      expect(data.playerCount, 5);
      expect(data.recommendation, PlayerCountRecommendation.best);
    });
  });

  group('PlayerCountRecommendations', () {
    late PlayerCountRecommendations recommendations;

    setUp(() {
      recommendations = PlayerCountRecommendations({
        1: PlayerCountRecommendation.notRecommended,
        2: PlayerCountRecommendation.recommended,
        3: PlayerCountRecommendation.best,
        4: PlayerCountRecommendation.best,
        5: PlayerCountRecommendation.recommended,
        6: PlayerCountRecommendation.notRecommended,
      });
    });

    test('should get best player counts', () {
      final bestCounts = recommendations.getBestPlayerCounts();
      expect(bestCounts, [3, 4]);
    });

    test('should get recommended player counts (including best)', () {
      final recommendedCounts = recommendations.getRecommendedPlayerCounts();
      expect(recommendedCounts, [2, 3, 4, 5]);
    });

    group('formatPlayerCountRange', () {
      test('should return empty string for empty list', () {
        expect(recommendations.formatPlayerCountRange([]), '');
      });

      test('should format single number', () {
        expect(recommendations.formatPlayerCountRange([3]), '3');
      });

      test('should format two consecutive numbers', () {
        expect(recommendations.formatPlayerCountRange([3, 4]), '3, 4');
      });

      test('should format range of three or more consecutive numbers', () {
        expect(recommendations.formatPlayerCountRange([2, 3, 4, 5]), '2-5');
      });

      test('should format mixed ranges and single numbers', () {
        expect(
          recommendations.formatPlayerCountRange([1, 3, 4, 5, 7]),
          '1, 3-5, 7',
        );
      });

      test('should format complex pattern', () {
        expect(
          recommendations.formatPlayerCountRange([1, 2, 4, 6, 7, 8, 10]),
          '1, 2, 4, 6-8, 10',
        );
      });
    });

    test('should get best with text', () {
      expect(recommendations.getBestWithText(), 'Best with 3, 4');
    });

    test('should get recommended with text', () {
      expect(recommendations.getRecommendedWithText(), 'Recommended with 2-5');
    });

    test('should return empty string when no best recommendations', () {
      final noBestrecommendations = PlayerCountRecommendations({
        2: PlayerCountRecommendation.recommended,
        3: PlayerCountRecommendation.notRecommended,
      });

      expect(noBestrecommendations.getBestWithText(), '');
    });

    test('should return empty string when no recommendations at all', () {
      final noRecommendations = PlayerCountRecommendations({
        2: PlayerCountRecommendation.notRecommended,
        3: PlayerCountRecommendation.notRecommended,
      });

      expect(noRecommendations.getRecommendedWithText(), '');
    });

    test('should convert to JSON correctly', () {
      final simpleRecommendations = PlayerCountRecommendations({
        2: PlayerCountRecommendation.recommended,
        3: PlayerCountRecommendation.best,
      });

      final json = simpleRecommendations.toJson();

      expect(json, {
        'recommendations': {'2': 'recommended', '3': 'best'},
      });
    });

    test('should create from JSON correctly', () {
      final json = {
        'recommendations': {
          '2': 'recommended',
          '3': 'best',
          '4': 'notRecommended',
        },
      };

      final recommendations = PlayerCountRecommendations.fromJson(json);

      expect(
        recommendations.recommendations[2],
        PlayerCountRecommendation.recommended,
      );
      expect(
        recommendations.recommendations[3],
        PlayerCountRecommendation.best,
      );
      expect(
        recommendations.recommendations[4],
        PlayerCountRecommendation.notRecommended,
      );
    });

    test('should handle edge cases in range formatting', () {
      // Test with non-consecutive numbers
      expect(recommendations.formatPlayerCountRange([1, 3, 5]), '1, 3, 5');

      // Test with large gaps
      expect(recommendations.formatPlayerCountRange([1, 10, 20]), '1, 10, 20');

      // Test with single pair
      expect(recommendations.formatPlayerCountRange([5, 6]), '5, 6');
    });
  });
}
