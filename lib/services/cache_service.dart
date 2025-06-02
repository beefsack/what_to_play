import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/board_game.dart';

class CacheService {
  static const String _collectionCachePrefix = 'collection_';
  static const String _thingCachePrefix = 'thing_';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getCollectionCacheFile(String username) async {
    final path = await _localPath;
    return File('$path/${_collectionCachePrefix}$username.json');
  }

  Future<File> _getThingCacheFile(String gameId) async {
    final path = await _localPath;
    return File('$path/${_thingCachePrefix}$gameId.json');
  }

  // Collection cache methods
  Future<void> cacheCollectionData(String username, String xmlData) async {
    try {
      final file = await _getCollectionCacheFile(username);
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': xmlData,
      };
      await file.writeAsString(jsonEncode(cacheData));
    } catch (e) {
      print('Error caching collection data for $username: $e');
    }
  }

  Future<String?> getCachedCollectionData(String username) async {
    try {
      final file = await _getCollectionCacheFile(username);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final cacheData = jsonDecode(contents) as Map<String, dynamic>;
      return cacheData['data'] as String?;
    } catch (e) {
      print('Error reading cached collection data for $username: $e');
      return null;
    }
  }

  Future<bool> hasCollectionCache(String username) async {
    try {
      final file = await _getCollectionCacheFile(username);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Thing cache methods
  Future<void> cacheThingData(String gameId, String xmlData) async {
    try {
      final file = await _getThingCacheFile(gameId);
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': xmlData,
      };
      await file.writeAsString(jsonEncode(cacheData));
    } catch (e) {
      print('Error caching thing data for $gameId: $e');
    }
  }

  Future<String?> getCachedThingData(String gameId) async {
    try {
      final file = await _getThingCacheFile(gameId);
      if (!await file.exists()) return null;

      final contents = await file.readAsString();
      final cacheData = jsonDecode(contents) as Map<String, dynamic>;
      return cacheData['data'] as String?;
    } catch (e) {
      print('Error reading cached thing data for $gameId: $e');
      return null;
    }
  }

  Future<bool> hasThingCache(String gameId) async {
    try {
      final file = await _getThingCacheFile(gameId);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getMissingThingCacheIds(List<String> gameIds) async {
    final missing = <String>[];
    for (final id in gameIds) {
      if (!await hasThingCache(id)) {
        missing.add(id);
      }
    }
    return missing;
  }

  // Cache management
  Future<void> clearCollectionCache(String username) async {
    try {
      final file = await _getCollectionCacheFile(username);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing collection cache for $username: $e');
    }
  }

  Future<void> clearThingCache(String gameId) async {
    try {
      final file = await _getThingCacheFile(gameId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing thing cache for $gameId: $e');
    }
  }

  Future<void> clearAllCache() async {
    try {
      final path = await _localPath;
      final directory = Directory(path);
      final files = await directory.list().toList();

      for (final file in files) {
        if (file is File) {
          final fileName = file.path.split('/').last;
          if (fileName.startsWith(_collectionCachePrefix) ||
              fileName.startsWith(_thingCachePrefix)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error clearing all cache: $e');
    }
  }
}
