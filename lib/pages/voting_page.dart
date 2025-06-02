import 'package:flutter/material.dart';
import 'dart:math';
import '../models/board_game.dart';
import '../widgets/board_game_card.dart';

enum VotingPhase { preparation, voting, results }

class VotingPage extends StatefulWidget {
  final List<BoardGame> availableGames;

  const VotingPage({super.key, required this.availableGames});

  @override
  State<VotingPage> createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> with TickerProviderStateMixin {
  VotingPhase _currentPhase = VotingPhase.preparation;
  List<BoardGame> _selectedGames = [];
  Map<BoardGame, int> _votes = {};
  late AnimationController _winnerAnimationController;
  late AnimationController _runnersUpAnimationController;
  late Animation<double> _winnerScaleAnimation;
  late Animation<double> _winnerOpacityAnimation;
  late Animation<double> _runnersUpOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectRandomGames();
  }

  void _initializeAnimations() {
    _winnerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _runnersUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _winnerScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _winnerAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _winnerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _winnerAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _runnersUpOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _runnersUpAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _winnerAnimationController.dispose();
    _runnersUpAnimationController.dispose();
    super.dispose();
  }

  void _selectRandomGames() {
    if (widget.availableGames.length <= 4) {
      _selectedGames = List.from(widget.availableGames);
    } else {
      final random = Random();
      final shuffled = List<BoardGame>.from(widget.availableGames)
        ..shuffle(random);
      _selectedGames = shuffled.take(4).toList();
    }
  }

  void _replaceGame(int index) {
    if (widget.availableGames.length <= 4) return;

    final availableReplacements =
        widget.availableGames
            .where((game) => !_selectedGames.contains(game))
            .toList();

    if (availableReplacements.isNotEmpty) {
      final random = Random();
      final replacement =
          availableReplacements[random.nextInt(availableReplacements.length)];

      setState(() {
        _selectedGames[index] = replacement;
      });
    }
  }

  void _proceedToVoting() {
    setState(() {
      _currentPhase = VotingPhase.voting;
      _votes.clear();
      for (final game in _selectedGames) {
        _votes[game] = 0;
      }
    });
  }

  void _voteForGame(BoardGame game) {
    setState(() {
      _votes[game] = (_votes[game] ?? 0) + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pass the device to the person on your left'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showTallyConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tally Votes'),
            content: const Text(
              'Are you sure you want to tally the votes and see the results?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue Voting'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedToResults();
                },
                child: const Text('Tally Votes'),
              ),
            ],
          ),
    );
  }

  void _proceedToResults() {
    setState(() {
      _currentPhase = VotingPhase.results;
    });

    // Start animations
    _winnerAnimationController.forward().then((_) {
      _runnersUpAnimationController.forward();
    });
  }

  BoardGame? get _winner {
    if (_votes.isEmpty) return null;
    return _votes.entries
        .where((entry) => entry.value > 0)
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<MapEntry<BoardGame, int>> get _runnersUp {
    if (_votes.isEmpty) return [];
    final winner = _winner;
    return _votes.entries
        .where((entry) => entry.value > 0 && entry.key != winner)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vote on what to play'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentPhase) {
      case VotingPhase.preparation:
        return _buildPreparationPhase();
      case VotingPhase.voting:
        return _buildVotingPhase();
      case VotingPhase.results:
        return _buildResultsPhase();
    }
  }

  Widget _buildPreparationPhase() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the size for each game card to fill the screen
                final availableWidth =
                    constraints.maxWidth - 16; // Account for spacing
                final availableHeight =
                    constraints.maxHeight - 16; // Account for spacing
                final cardWidth =
                    (availableWidth - 16) / 2; // 2 columns with spacing
                final cardHeight =
                    (availableHeight - 16) / 2; // 2 rows with spacing

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: cardWidth / cardHeight,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _selectedGames.length,
                  itemBuilder: (context, index) {
                    return Dismissible(
                      key: Key(_selectedGames[index].id),
                      onDismissed: (_) => _replaceGame(index),
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      child: BoardGameCard(game: _selectedGames[index]),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _proceedToVoting,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Proceed to voting',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVotingPhase() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate the size for each game card to fill the screen
                final availableWidth =
                    constraints.maxWidth - 16; // Account for spacing
                final availableHeight =
                    constraints.maxHeight - 16; // Account for spacing
                final cardWidth =
                    (availableWidth - 16) / 2; // 2 columns with spacing
                final cardHeight =
                    (availableHeight - 16) / 2; // 2 rows with spacing

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: cardWidth / cardHeight,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _selectedGames.length,
                  itemBuilder: (context, index) {
                    final game = _selectedGames[index];
                    return GestureDetector(
                      onTap: () => _voteForGame(game),
                      child: BoardGameCard(game: game),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showTallyConfirmation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Tally votes', style: TextStyle(fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsPhase() {
    final winner = _winner;
    final runnersUp = _runnersUp;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (winner != null) ...[
                  const Text(
                    '🎉 Winner! 🎉',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  AnimatedBuilder(
                    animation: _winnerAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _winnerScaleAnimation.value,
                        child: Opacity(
                          opacity: _winnerOpacityAnimation.value,
                          child: Column(
                            children: [
                              SizedBox(
                                width: 250,
                                height: 333,
                                child: BoardGameCard(game: winner),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${_votes[winner]} votes',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (runnersUp.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    AnimatedBuilder(
                      animation: _runnersUpAnimationController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _runnersUpOpacityAnimation.value,
                          child: Column(
                            children: [
                              const Text(
                                'Runners Up',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children:
                                    runnersUp.map((entry) {
                                      return Column(
                                        children: [
                                          SizedBox(
                                            width: 100,
                                            height: 133,
                                            child: BoardGameCard(
                                              game: entry.key,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${entry.value} votes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ] else ...[
                  const Text(
                    'No votes were cast!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Return to collection',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
