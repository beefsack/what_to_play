import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:what_to_play/models/collection.dart';
import 'package:what_to_play/services/collection_service.dart';

void main() {
  group('CollectionService', () {
    late CollectionService service;

    setUp(() {
      service = CollectionService();
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return empty list when no collections exist', () async {
      final collections = await service.getCollections();
      expect(collections, isEmpty);
    });

    test('should save and retrieve collections', () async {
      const collection1 = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'user1',
      );
      const collection2 = Collection(
        id: '2',
        name: 'Family Games',
        bggUsername: 'user2',
      );

      await service.saveCollections([collection1, collection2]);
      final retrievedCollections = await service.getCollections();

      expect(retrievedCollections, hasLength(2));
      expect(retrievedCollections[0], equals(collection1));
      expect(retrievedCollections[1], equals(collection2));
    });

    test('should add collection to existing list', () async {
      const existingCollection = Collection(
        id: '1',
        name: 'Existing Games',
        bggUsername: 'user1',
      );
      await service.saveCollections([existingCollection]);

      const newCollection = Collection(
        id: '2',
        name: 'New Games',
        bggUsername: 'user2',
      );
      await service.addCollection(newCollection);

      final collections = await service.getCollections();
      expect(collections, hasLength(2));
      expect(collections[0], equals(existingCollection));
      expect(collections[1], equals(newCollection));
    });

    test('should update existing collection', () async {
      const originalCollection = Collection(
        id: '1',
        name: 'Original Name',
        bggUsername: 'user1',
      );
      await service.saveCollections([originalCollection]);

      const updatedCollection = Collection(
        id: '1',
        name: 'Updated Name',
        bggUsername: 'user1',
      );
      await service.updateCollection(updatedCollection);

      final collections = await service.getCollections();
      expect(collections, hasLength(1));
      expect(collections[0].name, 'Updated Name');
      expect(collections[0].id, '1');
    });

    test('should not update non-existent collection', () async {
      const existingCollection = Collection(
        id: '1',
        name: 'Existing',
        bggUsername: 'user1',
      );
      await service.saveCollections([existingCollection]);

      const nonExistentCollection = Collection(
        id: '999',
        name: 'Non-existent',
        bggUsername: 'user2',
      );
      await service.updateCollection(nonExistentCollection);

      final collections = await service.getCollections();
      expect(collections, hasLength(1));
      expect(collections[0], equals(existingCollection));
    });

    test('should delete collection by id', () async {
      const collection1 = Collection(
        id: '1',
        name: 'Keep This',
        bggUsername: 'user1',
      );
      const collection2 = Collection(
        id: '2',
        name: 'Delete This',
        bggUsername: 'user2',
      );
      await service.saveCollections([collection1, collection2]);

      await service.deleteCollection('2');

      final collections = await service.getCollections();
      expect(collections, hasLength(1));
      expect(collections[0], equals(collection1));
    });

    test('should not fail when deleting non-existent collection', () async {
      const collection = Collection(
        id: '1',
        name: 'Existing',
        bggUsername: 'user1',
      );
      await service.saveCollections([collection]);

      await service.deleteCollection('999');

      final collections = await service.getCollections();
      expect(collections, hasLength(1));
      expect(collections[0], equals(collection));
    });

    group('isNameUnique', () {
      test('should return true for unique name', () async {
        const collection = Collection(
          id: '1',
          name: 'Existing Name',
          bggUsername: 'user1',
        );
        await service.saveCollections([collection]);

        final isUnique = await service.isNameUnique('New Name');
        expect(isUnique, isTrue);
      });

      test(
        'should return false for duplicate name (case insensitive)',
        () async {
          const collection = Collection(
            id: '1',
            name: 'Existing Name',
            bggUsername: 'user1',
          );
          await service.saveCollections([collection]);

          expect(await service.isNameUnique('Existing Name'), isFalse);
          expect(await service.isNameUnique('existing name'), isFalse);
          expect(await service.isNameUnique('EXISTING NAME'), isFalse);
        },
      );

      test('should return true when excluding the same collection', () async {
        const collection = Collection(
          id: '1',
          name: 'Existing Name',
          bggUsername: 'user1',
        );
        await service.saveCollections([collection]);

        final isUnique = await service.isNameUnique(
          'Existing Name',
          excludeId: '1',
        );
        expect(isUnique, isTrue);
      });

      test(
        'should return false when name exists in different collection',
        () async {
          const collection1 = Collection(
            id: '1',
            name: 'Name One',
            bggUsername: 'user1',
          );
          const collection2 = Collection(
            id: '2',
            name: 'Name Two',
            bggUsername: 'user2',
          );
          await service.saveCollections([collection1, collection2]);

          final isUnique = await service.isNameUnique(
            'Name Two',
            excludeId: '1',
          );
          expect(isUnique, isFalse);
        },
      );
    });

    test('should generate unique IDs', () async {
      final id1 = service.generateId();
      // Add a small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 1));
      final id2 = service.generateId();

      expect(id1, isNotEmpty);
      expect(id2, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });

    test('should handle corrupted data gracefully', () async {
      // Simulate corrupted data in SharedPreferences
      SharedPreferences.setMockInitialValues({'collections': 'invalid json'});

      final collections = await service.getCollections();
      expect(collections, isEmpty);
    });

    test('should handle empty collections list', () async {
      await service.saveCollections([]);
      final collections = await service.getCollections();
      expect(collections, isEmpty);
    });

    test('should preserve collection order', () async {
      const collection1 = Collection(
        id: '1',
        name: 'First',
        bggUsername: 'user1',
      );
      const collection2 = Collection(
        id: '2',
        name: 'Second',
        bggUsername: 'user2',
      );
      const collection3 = Collection(
        id: '3',
        name: 'Third',
        bggUsername: 'user3',
      );

      await service.saveCollections([collection1, collection2, collection3]);
      final collections = await service.getCollections();

      expect(collections[0].name, 'First');
      expect(collections[1].name, 'Second');
      expect(collections[2].name, 'Third');
    });
  });
}
