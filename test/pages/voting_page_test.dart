import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_play/models/board_game.dart';
import 'package:what_to_play/models/player_count_recommendation.dart';
import 'package:what_to_play/pages/voting_page.dart';

void main() {
  group('VotingPage', () {
    late List<BoardGame> testGames;

    setUp(() {
      testGames = [
        BoardGame(
          id: '1',
          name: 'Test Game 1',
          imageUrl: 'https://example.com/image1.jpg',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          yearPublished: 2020,
          minPlayers: 2,
          maxPlayers: 4,
          playingTime: 60,
          minAge: 10,
          averageWeight: 2.5,
          playerCountRecommendations: PlayerCountRecommendations({
            2: PlayerCountRecommendation.recommended,
            3: PlayerCountRecommendation.best,
            4: PlayerCountRecommendation.recommended,
          }),
        ),
        BoardGame(
          id: '2',
          name: 'Test Game 2',
          imageUrl: 'https://example.com/image2.jpg',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          yearPublished: 2021,
          minPlayers: 1,
          maxPlayers: 2,
          playingTime: 30,
          minAge: 8,
          averageWeight: 1.5,
          playerCountRecommendations: PlayerCountRecommendations({
            1: PlayerCountRecommendation.recommended,
            2: PlayerCountRecommendation.best,
          }),
        ),
      ];
    });

    testWidgets('should disable tally votes button initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: VotingPage(availableGames: testGames)),
      );

      // Navigate to voting phase
      await tester.tap(find.text('Proceed to voting'));
      await tester.pump();

      // Find the tally votes button
      final tallyButton = find.text('Tally votes');
      expect(tallyButton, findsOneWidget);

      // Check that the button is disabled (onPressed should be null)
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: tallyButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNull);
    });

    testWidgets('should enable tally votes button after first vote', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: VotingPage(availableGames: testGames)),
      );

      // Navigate to voting phase
      await tester.tap(find.text('Proceed to voting'));
      await tester.pump();

      // Vote for the first game
      await tester.tap(find.text('Test Game 1'));
      await tester.pump();

      // Find the tally votes button
      final tallyButton = find.text('Tally votes');
      expect(tallyButton, findsOneWidget);

      // Check that the button is now enabled (onPressed should not be null)
      final elevatedButton = tester.widget<ElevatedButton>(
        find.ancestor(of: tallyButton, matching: find.byType(ElevatedButton)),
      );
      expect(elevatedButton.onPressed, isNotNull);
    });
  });
}
