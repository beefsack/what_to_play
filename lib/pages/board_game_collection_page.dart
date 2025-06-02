import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../models/game_filter.dart';
import '../models/player_count_recommendation.dart';
import '../services/bgg_service.dart';
import '../widgets/board_game_card.dart';
import '../widgets/game_filter_widget.dart';

class BoardGameCollectionPage extends StatefulWidget {
  final String username;
  final String? collectionName;

  const BoardGameCollectionPage({
    super.key,
    required this.username,
    this.collectionName,
  });

  @override
  State<BoardGameCollectionPage> createState() =>
      _BoardGameCollectionPageState();
}

class _BoardGameCollectionPageState extends State<BoardGameCollectionPage> {
  final BGGService _bggService = BGGService();
  List<BoardGame> _allGames = [];
  List<BoardGame> _filteredGames = [];
  bool _isLoading = false;
  String? _error;
  String _loadingStatus = '';
  double? _loadingProgress;
  GameFilter _currentFilter = GameFilter();

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<void> _loadCollection() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _loadingStatus = 'Starting...';
      _loadingProgress = null;
    });

    try {
      final games = await _bggService.getCollection(
        widget.username,
        onProgress: (status, {progress}) {
          if (mounted) {
            setState(() {
              _loadingStatus = status;
              _loadingProgress = progress;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _allGames = games;
          _filteredGames = games;
          _isLoading = false;
          _loadingStatus = '';
          _loadingProgress = null;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _loadingStatus = '';
          _loadingProgress = null;
        });
      }
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredGames =
          _allGames.where((game) {
            // Player count filter
            if (_currentFilter.playerCount != null) {
              final playerCount = _currentFilter.playerCount!;
              switch (_currentFilter.playerCountType) {
                case PlayerCountFilterType.best:
                  final bestCounts =
                      game.playerCountRecommendations.getBestPlayerCounts();
                  if (!bestCounts.contains(playerCount)) return false;
                  break;
                case PlayerCountFilterType.recommended:
                  final recommendedCounts =
                      game.playerCountRecommendations
                          .getRecommendedPlayerCounts();
                  if (!recommendedCounts.contains(playerCount)) return false;
                  break;
                case PlayerCountFilterType.minMax:
                  if (playerCount < game.minPlayers ||
                      playerCount > game.maxPlayers)
                    return false;
                  break;
              }
            }

            // Time filters
            if (_currentFilter.minTime != null &&
                game.playingTime < _currentFilter.minTime!) {
              return false;
            }
            if (_currentFilter.maxTime != null &&
                game.playingTime > _currentFilter.maxTime!) {
              return false;
            }

            // Weight filters
            if (_currentFilter.minWeight != null &&
                game.averageWeight < _currentFilter.minWeight!) {
              return false;
            }
            if (_currentFilter.maxWeight != null &&
                game.averageWeight > _currentFilter.maxWeight!) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => GameFilterWidget(
            initialFilter: _currentFilter,
            onFilterChanged: (newFilter) {
              setState(() {
                _currentFilter = newFilter;
              });
              _applyFilter();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.collectionName ?? 'Board Game Collection'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color:
                  _currentFilter.hasActiveFilters
                      ? Theme.of(context).colorScheme.primary
                      : null,
            ),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCollection,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _loadingStatus.isNotEmpty
                    ? _loadingStatus
                    : 'Loading board game collection...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (_loadingProgress != null) ...[
                LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_loadingProgress! * 100).round()}%',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ] else ...[
                const Text(
                  'This may take a moment as we fetch game details',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading collection',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCollection,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allGames.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.games_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No games found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text(
              'The collection appears to be empty',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_filteredGames.isEmpty && _currentFilter.hasActiveFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No games match your filters',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your filter criteria',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _showFilterDialog,
              child: const Text('Adjust Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Collection info header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.collectionName ?? '${widget.username}\'s Collection',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredGames.length} of ${_allGames.length} games • BGG User: ${widget.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_currentFilter.hasActiveFilters) ...[
                const SizedBox(height: 4),
                Text(
                  'Filters: ${_currentFilter.getActiveFiltersDescription()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Games grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate number of columns based on screen width
                // Each card should be approximately 200px wide
                const double cardWidth = 200.0;
                const double spacing = 8.0;
                final int crossAxisCount = ((constraints.maxWidth + spacing) /
                        (cardWidth + spacing))
                    .floor()
                    .clamp(1, 10);

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: _filteredGames.length,
                  itemBuilder: (context, index) {
                    return BoardGameCard(game: _filteredGames[index]);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
