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
  late AnimationController _overlayAnimationController;
  late Animation<double> _winnerScaleAnimation;
  late Animation<double> _winnerOpacityAnimation;
  late Animation<double> _runnersUpOpacityAnimation;
  late Animation<double> _overlayOpacityAnimation;
  bool _showPassDeviceOverlay = false;

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
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _overlayOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _winnerAnimationController.dispose();
    _runnersUpAnimationController.dispose();
    _overlayAnimationController.dispose();
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

  bool get _canReplaceGames => widget.availableGames.length > 4;

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

    _showPassDeviceMessage();
  }

  void _showPassDeviceMessage() {
    setState(() {
      _showPassDeviceOverlay = true;
    });

    _overlayAnimationController.forward().then((_) {
      // Keep overlay visible for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _overlayAnimationController.reverse().then((_) {
            if (mounted) {
              setState(() {
                _showPassDeviceOverlay = false;
              });
            }
          });
        }
      });
    });
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
                  itemCount: 4, // Always show 4 slots
                  itemBuilder: (context, index) {
                    if (index >= _selectedGames.length) {
                      // Empty slot for missing games
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        ),
                      );
                    }

                    final game = _selectedGames[index];
                    final gameCard = BoardGameCard(game: game);

                    if (!_canReplaceGames) {
                      // No dismissible behavior when there are no replacement games
                      return gameCard;
                    }

                    return Dismissible(
                      key: Key(game.id),
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
                      child: gameCard,
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
    return Stack(
      children: [
        Column(
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
                      itemCount: 4, // Always show 4 slots
                      itemBuilder: (context, index) {
                        if (index >= _selectedGames.length) {
                          // Empty slot for missing games
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                          );
                        }

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
                  child: const Text(
                    'Tally votes',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Pass device overlay
        if (_showPassDeviceOverlay)
          AnimatedBuilder(
            animation: _overlayAnimationController,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayOpacityAnimation.value,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_horiz,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Pass the device to the person on your left',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
