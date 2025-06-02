import 'package:flutter_test/flutter_test.dart';
import 'package:what_to_play/models/collection.dart';

void main() {
  group('Collection', () {
    test('should create a collection with required fields', () {
      const collection = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      expect(collection.id, '1');
      expect(collection.name, 'My Games');
      expect(collection.bggUsername, 'testuser');
    });

    test('should convert to JSON correctly', () {
      const collection = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      final json = collection.toJson();

      expect(json, {'id': '1', 'name': 'My Games', 'bggUsername': 'testuser'});
    });

    test('should create from JSON correctly', () {
      final json = {'id': '1', 'name': 'My Games', 'bggUsername': 'testuser'};

      final collection = Collection.fromJson(json);

      expect(collection.id, '1');
      expect(collection.name, 'My Games');
      expect(collection.bggUsername, 'testuser');
    });

    test('should create copy with updated fields', () {
      const original = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      final updated = original.copyWith(name: 'Updated Games');

      expect(updated.id, '1');
      expect(updated.name, 'Updated Games');
      expect(updated.bggUsername, 'testuser');
      expect(original.name, 'My Games'); // Original unchanged
    });

    test('should implement equality correctly', () {
      const collection1 = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      const collection2 = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      const collection3 = Collection(
        id: '2',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      expect(collection1, equals(collection2));
      expect(collection1, isNot(equals(collection3)));
    });

    test('should have consistent hashCode for equal objects', () {
      const collection1 = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      const collection2 = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      expect(collection1.hashCode, equals(collection2.hashCode));
    });

    test('should have meaningful toString representation', () {
      const collection = Collection(
        id: '1',
        name: 'My Games',
        bggUsername: 'testuser',
      );

      final stringRepresentation = collection.toString();

      expect(stringRepresentation, contains('Collection'));
      expect(stringRepresentation, contains('1'));
      expect(stringRepresentation, contains('My Games'));
      expect(stringRepresentation, contains('testuser'));
    });
  });
}
