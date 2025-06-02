import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/collection.dart';

class CollectionService {
  static const String _collectionsKey = 'collections';
  final Logger _logger = Logger('CollectionService');

  Future<List<Collection>> getCollections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionsJson = prefs.getString(_collectionsKey);

      if (collectionsJson == null) {
        return [];
      }

      final List<dynamic> collectionsList = jsonDecode(collectionsJson);
      return collectionsList
          .map((json) => Collection.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.severe('Error loading collections: $e');
      return [];
    }
  }

  Future<void> saveCollections(List<Collection> collections) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionsJson = jsonEncode(
        collections.map((collection) => collection.toJson()).toList(),
      );
      await prefs.setString(_collectionsKey, collectionsJson);
    } catch (e) {
      _logger.severe('Error saving collections: $e');
    }
  }

  Future<void> addCollection(Collection collection) async {
    final collections = await getCollections();
    collections.add(collection);
    await saveCollections(collections);
  }

  Future<void> updateCollection(Collection updatedCollection) async {
    final collections = await getCollections();
    final index = collections.indexWhere((c) => c.id == updatedCollection.id);
    if (index != -1) {
      collections[index] = updatedCollection;
      await saveCollections(collections);
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    final collections = await getCollections();
    collections.removeWhere((c) => c.id == collectionId);
    await saveCollections(collections);
  }

  Future<bool> isNameUnique(String name, {String? excludeId}) async {
    final collections = await getCollections();
    return !collections.any(
      (c) => c.name.toLowerCase() == name.toLowerCase() && c.id != excludeId,
    );
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
