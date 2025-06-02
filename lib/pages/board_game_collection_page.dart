import 'package:flutter/material.dart';
import '../models/board_game.dart';
import '../services/bgg_service.dart';
import '../widgets/board_game_card.dart';

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
  List<BoardGame> _games = [];
  bool _isLoading = false;
  String? _error;
  String _loadingStatus = '';
  double? _loadingProgress;

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
          setState(() {
            _loadingStatus = status;
            _loadingProgress = progress;
          });
        },
      );
      setState(() {
        _games = games;
        _isLoading = false;
        _loadingStatus = '';
        _loadingProgress = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _loadingStatus = '';
        _loadingProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.collectionName ?? 'Board Game Collection'),
        actions: [
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

    if (_games.isEmpty) {
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
                '${_games.length} games • BGG User: ${widget.username}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Games grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                return BoardGameCard(game: _games[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
