import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/board_game.dart';
import '../models/player_count_recommendation.dart';
import 'cache_service.dart';

typedef ProgressCallback = void Function(String status, {double? progress});

class BGGService {
  static const String baseUrl = 'https://boardgamegeek.com/xmlapi2';
  static const Duration rateLimitDelay = Duration(seconds: 5);
  static const int maxRetries = 10;

  static DateTime? _lastRequestTime;
  final CacheService _cacheService = CacheService();

  Future<List<BoardGame>> getCollection(
    String username, {
    ProgressCallback? onProgress,
  }) async {
    return await _getCollectionWithCache(username, onProgress: onProgress);
  }

  Future<List<BoardGame>> _getCollectionWithCache(
    String username, {
    ProgressCallback? onProgress,
  }) async {
    try {
      // Check if we have cached collection data
      String? collectionXml = await _cacheService.getCachedCollectionData(
        username,
      );

      if (collectionXml == null) {
        // No cache, fetch from API
        onProgress?.call('Fetching collection from BoardGameGeek...');
        print('No cached collection data for $username, fetching from API...');
        final collectionUri = Uri.parse(
          '$baseUrl/collection?own=1&excludesubtype=boardgameexpansion&username=$username',
        );
        final collectionResponse = await _makeRequestWithRetry(
          collectionUri,
          onProgress: onProgress,
        );
        collectionXml = collectionResponse.body;

        // Cache the collection data
        await _cacheService.cacheCollectionData(username, collectionXml);
        onProgress?.call('Collection data cached');
      } else {
        onProgress?.call('Using cached collection data');
        print('Using cached collection data for $username');
      }

      final collectionDocument = XmlDocument.parse(collectionXml);
      final items = collectionDocument.findAllElements('item');

      if (items.isEmpty) {
        return [];
      }

      // Extract object IDs
      final objectIds =
          items
              .map((item) => item.getAttribute('objectid'))
              .where((id) => id != null)
              .cast<String>()
              .toList();

      if (objectIds.isEmpty) {
        return [];
      }

      // Check which thing data we need to fetch
      final missingIds = await _cacheService.getMissingThingCacheIds(objectIds);

      if (missingIds.isNotEmpty) {
        print('Fetching missing thing data for ${missingIds.length} games...');
        await _fetchAndCacheThingData(missingIds, onProgress: onProgress);
      } else {
        onProgress?.call('All game data is cached');
        print('All thing data is cached');
      }

      // Now build the games from cached data
      final games = <BoardGame>[];
      final collectionMap = <String, XmlElement>{};

      for (final item in items) {
        final id = item.getAttribute('objectid');
        if (id != null) {
          collectionMap[id] = item;
        }
      }

      for (final objectId in objectIds) {
        final cachedThingXml = await _cacheService.getCachedThingData(objectId);
        if (cachedThingXml == null) continue;

        final thingDocument = XmlDocument.parse(cachedThingXml);
        final thingItems = thingDocument.findAllElements('item');

        for (final thingItem in thingItems) {
          final id = thingItem.getAttribute('id');
          if (id == objectId) {
            final collectionItem = collectionMap[id];
            if (collectionItem != null) {
              try {
                final game = _parseGameFromXml(thingItem, collectionItem);
                games.add(game);
              } catch (e) {
                print('Error parsing game $id: $e');
              }
            }
            break;
          }
        }
      }

      return games;
    } catch (e) {
      print('Error fetching collection with cache: $e');
      throw Exception('Failed to load collection: $e');
    }
  }

  Future<void> _fetchAndCacheThingData(
    List<String> gameIds, {
    ProgressCallback? onProgress,
  }) async {
    const batchSize = 20;
    final totalBatches = (gameIds.length / batchSize).ceil();

    for (int i = 0; i < gameIds.length; i += batchSize) {
      final batchNumber = (i / batchSize).floor() + 1;
      final batch = gameIds.skip(i).take(batchSize).toList();

      final progress = batchNumber / totalBatches;
      onProgress?.call(
        'Fetching game details ($batchNumber/$totalBatches batches)',
        progress: progress,
      );

      final detailsUri = Uri.parse(
        '$baseUrl/thing?stats=1&id=${batch.join(',')}',
      );
      final detailsResponse = await _makeRequestWithRetry(detailsUri);

      // Cache each individual game's data
      final detailsDocument = XmlDocument.parse(detailsResponse.body);
      final items = detailsDocument.findAllElements('item');

      for (final item in items) {
        final id = item.getAttribute('id');
        if (id != null) {
          // Create a minimal XML document for this single item
          final singleItemXml =
              '<?xml version="1.0" encoding="utf-8"?><items>${item.toXmlString()}</items>';
          await _cacheService.cacheThingData(id, singleItemXml);
        }
      }
    }

    onProgress?.call('Game details cached', progress: 1.0);
  }

  Future<void> _enforceRateLimit() async {
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < rateLimitDelay) {
        final waitTime = rateLimitDelay - timeSinceLastRequest;
        print('Rate limiting: waiting ${waitTime.inMilliseconds}ms');
        await Future.delayed(waitTime);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  Future<http.Response> _makeRateLimitedRequest(Uri uri) async {
    await _enforceRateLimit();
    return await http.get(uri);
  }

  Future<http.Response> _makeRequestWithRetry(
    Uri uri, {
    ProgressCallback? onProgress,
  }) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final response = await _makeRateLimitedRequest(uri);

      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode == 202) {
        onProgress?.call('BGG server building collection, retrying...');
        print(
          'Received 202 response, attempt ${attempt + 1}/$maxRetries. Retrying...',
        );
        if (attempt < maxRetries - 1) {
          // Rate limiter will handle the delay for the next request
          continue;
        }
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    }

    throw Exception(
      'Max retries ($maxRetries) exceeded for request to ${uri.toString()}',
    );
  }

  BoardGame _parseGameFromXml(
    XmlElement detailItem,
    XmlElement collectionItem,
  ) {
    final id = detailItem.getAttribute('id') ?? '';

    // Get name
    final nameElement = detailItem
        .findElements('name')
        .firstWhere(
          (element) => element.getAttribute('type') == 'primary',
          orElse: () => detailItem.findElements('name').first,
        );
    final name = nameElement.getAttribute('value') ?? 'Unknown';

    // Get images
    final imageUrl =
        detailItem.findElements('image').firstOrNull?.innerText ?? '';
    final thumbnailUrl =
        detailItem.findElements('thumbnail').firstOrNull?.innerText ??
        collectionItem.findElements('thumbnail').firstOrNull?.innerText ??
        '';

    // Get year published
    final yearElement = detailItem.findElements('yearpublished').firstOrNull;
    final yearPublished =
        int.tryParse(yearElement?.getAttribute('value') ?? '0') ?? 0;

    // Get player count
    final minPlayersElement = detailItem.findElements('minplayers').firstOrNull;
    final maxPlayersElement = detailItem.findElements('maxplayers').firstOrNull;
    final minPlayers =
        int.tryParse(minPlayersElement?.getAttribute('value') ?? '1') ?? 1;
    final maxPlayers =
        int.tryParse(maxPlayersElement?.getAttribute('value') ?? '1') ?? 1;

    // Get playing time
    final playingTimeElement =
        detailItem.findElements('playingtime').firstOrNull;
    final playingTime =
        int.tryParse(playingTimeElement?.getAttribute('value') ?? '0') ?? 0;

    // Get minimum age
    final minAgeElement = detailItem.findElements('minage').firstOrNull;
    final minAge =
        int.tryParse(minAgeElement?.getAttribute('value') ?? '0') ?? 0;

    // Get average weight
    final statisticsElement = detailItem.findElements('statistics').firstOrNull;
    final ratingsElement =
        statisticsElement?.findElements('ratings').firstOrNull;
    final averageWeightElement =
        ratingsElement?.findElements('averageweight').firstOrNull;
    final averageWeight =
        double.tryParse(averageWeightElement?.getAttribute('value') ?? '0') ??
        0.0;

    // Get player count recommendations
    final playerCountRecommendations = _getPlayerCountRecommendations(
      detailItem,
    );

    return BoardGame(
      id: id,
      name: name,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      yearPublished: yearPublished,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      playingTime: playingTime,
      minAge: minAge,
      averageWeight: averageWeight,
      playerCountRecommendations: playerCountRecommendations,
    );
  }

  PlayerCountRecommendations _getPlayerCountRecommendations(XmlElement item) {
    final polls = item.findAllElements('poll');
    final playerCountPoll =
        polls
            .where(
              (poll) => poll.getAttribute('name') == 'suggested_numplayers',
            )
            .firstOrNull;

    final recommendations = <int, PlayerCountRecommendation>{};

    if (playerCountPoll != null) {
      final results = playerCountPoll.findAllElements('results');

      for (final result in results) {
        final numPlayersStr = result.getAttribute('numplayers');
        if (numPlayersStr == null) continue;

        // Handle special cases like "1+" or "2+"
        int? numPlayers;
        if (numPlayersStr.endsWith('+')) {
          numPlayers = int.tryParse(
            numPlayersStr.substring(0, numPlayersStr.length - 1),
          );
        } else {
          numPlayers = int.tryParse(numPlayersStr);
        }

        if (numPlayers == null) continue;

        // Get vote counts for each recommendation type
        int bestVotes = 0;
        int recommendedVotes = 0;
        int notRecommendedVotes = 0;

        final resultElements = result.findAllElements('result');
        for (final resultElement in resultElements) {
          final value = resultElement.getAttribute('value');
          final numVotesStr = resultElement.getAttribute('numvotes');
          final numVotes = int.tryParse(numVotesStr ?? '0') ?? 0;

          switch (value) {
            case 'Best':
              bestVotes = numVotes;
              break;
            case 'Recommended':
              recommendedVotes = numVotes;
              break;
            case 'Not Recommended':
              notRecommendedVotes = numVotes;
              break;
          }
        }

        // Apply the logic for determining recommendation
        PlayerCountRecommendation recommendation;
        if (bestVotes > (recommendedVotes + notRecommendedVotes)) {
          recommendation = PlayerCountRecommendation.best;
        } else if ((bestVotes + recommendedVotes) > notRecommendedVotes) {
          recommendation = PlayerCountRecommendation.recommended;
        } else {
          recommendation = PlayerCountRecommendation.notRecommended;
        }

        recommendations[numPlayers] = recommendation;
      }
    }

    return PlayerCountRecommendations(recommendations);
  }
}
