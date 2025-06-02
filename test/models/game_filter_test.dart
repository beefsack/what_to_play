import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_play/models/game_filter.dart';

void main() {
  group('PlayerCountFilterType', () {
    test('should have correct string representations', () {
      expect(PlayerCountFilterType.best.toString(), 'Best');
      expect(PlayerCountFilterType.recommended.toString(), 'Recommended');
      expect(PlayerCountFilterType.minMax.toString(), 'Min/Max');
    });
  });

  group('GameFilter', () {
    test('should create empty filter with default values', () {
      final filter = GameFilter();

      expect(filter.playerCount, isNull);
      expect(filter.playerCountType, PlayerCountFilterType.recommended);
      expect(filter.minTime, isNull);
      expect(filter.maxTime, isNull);
      expect(filter.minWeight, isNull);
      expect(filter.maxWeight, isNull);
      expect(filter.minAge, isNull);
      expect(filter.hasActiveFilters, isFalse);
    });

    test('should create filter with specified values', () {
      final filter = GameFilter(
        playerCount: 4,
        playerCountType: PlayerCountFilterType.best,
        minTime: 30,
        maxTime: 120,
        minWeight: 2.0,
        maxWeight: 4.0,
        minAge: 12,
      );

      expect(filter.playerCount, 4);
      expect(filter.playerCountType, PlayerCountFilterType.best);
      expect(filter.minTime, 30);
      expect(filter.maxTime, 120);
      expect(filter.minWeight, 2.0);
      expect(filter.maxWeight, 4.0);
      expect(filter.minAge, 12);
      expect(filter.hasActiveFilters, isTrue);
    });

    test('should detect active filters correctly', () {
      expect(GameFilter().hasActiveFilters, isFalse);
      expect(GameFilter(playerCount: 4).hasActiveFilters, isTrue);
      expect(GameFilter(minTime: 30).hasActiveFilters, isTrue);
      expect(GameFilter(maxTime: 120).hasActiveFilters, isTrue);
      expect(GameFilter(minWeight: 2.0).hasActiveFilters, isTrue);
      expect(GameFilter(maxWeight: 4.0).hasActiveFilters, isTrue);
      expect(GameFilter(minAge: 12).hasActiveFilters, isTrue);
    });

    test('should copy with updated values', () {
      final original = GameFilter(playerCount: 4, minTime: 30, minWeight: 2.0);

      final updated = original.copyWith(playerCount: 6, maxTime: 120);

      expect(updated.playerCount, 6);
      expect(updated.minTime, 30); // Preserved
      expect(updated.maxTime, 120); // New value
      expect(updated.minWeight, 2.0); // Preserved
    });

    test('should clear specific values when copying', () {
      final original = GameFilter(
        playerCount: 4,
        minTime: 30,
        maxTime: 120,
        minWeight: 2.0,
        maxWeight: 4.0,
        minAge: 12,
      );

      final updated = original.copyWith(
        clearPlayerCount: true,
        clearMinTime: true,
        clearMaxWeight: true,
      );

      expect(updated.playerCount, isNull);
      expect(updated.minTime, isNull);
      expect(updated.maxTime, 120); // Preserved
      expect(updated.minWeight, 2.0); // Preserved
      expect(updated.maxWeight, isNull);
      expect(updated.minAge, 12); // Preserved
    });

    test('should clear all filters', () {
      final original = GameFilter(
        playerCount: 4,
        minTime: 30,
        maxTime: 120,
        minWeight: 2.0,
        maxWeight: 4.0,
        minAge: 12,
      );

      final cleared = original.clear();

      expect(cleared.playerCount, isNull);
      expect(cleared.minTime, isNull);
      expect(cleared.maxTime, isNull);
      expect(cleared.minWeight, isNull);
      expect(cleared.maxWeight, isNull);
      expect(cleared.minAge, isNull);
      expect(cleared.hasActiveFilters, isFalse);
    });

    group('getActiveFiltersDescription', () {
      test('should return empty string for no filters', () {
        final filter = GameFilter();
        expect(filter.getActiveFiltersDescription(), '');
      });

      test('should describe player count filter', () {
        final filter = GameFilter(
          playerCount: 4,
          playerCountType: PlayerCountFilterType.best,
        );
        expect(filter.getActiveFiltersDescription(), 'Best: 4 players');
      });

      test('should describe time range filters', () {
        expect(
          GameFilter(minTime: 30, maxTime: 120).getActiveFiltersDescription(),
          'Time: 30-120min',
        );
        expect(
          GameFilter(minTime: 30).getActiveFiltersDescription(),
          'Time: 30min+',
        );
        expect(
          GameFilter(maxTime: 120).getActiveFiltersDescription(),
          'Time: ≤120min',
        );
      });

      test('should describe weight range filters', () {
        expect(
          GameFilter(
            minWeight: 2.0,
            maxWeight: 4.0,
          ).getActiveFiltersDescription(),
          'Weight: 2.0-4.0',
        );
        expect(
          GameFilter(minWeight: 2.5).getActiveFiltersDescription(),
          'Weight: 2.5+',
        );
        expect(
          GameFilter(maxWeight: 3.5).getActiveFiltersDescription(),
          'Weight: ≤3.5',
        );
      });

      test('should describe age filter', () {
        final filter = GameFilter(minAge: 12);
        expect(filter.getActiveFiltersDescription(), 'Age: 12+');
      });

      test('should combine multiple filters', () {
        final filter = GameFilter(
          playerCount: 4,
          playerCountType: PlayerCountFilterType.recommended,
          minTime: 30,
          maxTime: 120,
          minWeight: 2.0,
          minAge: 12,
        );

        final description = filter.getActiveFiltersDescription();
        expect(description, contains('Recommended: 4 players'));
        expect(description, contains('Time: 30-120min'));
        expect(description, contains('Weight: 2.0+'));
        expect(description, contains('Age: 12+'));
      });
    });
  });
}
