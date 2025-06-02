import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import 'board_game_collection_page.dart';
import 'add_edit_collection_page.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final CollectionService _collectionService = CollectionService();
  List<Collection> _collections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final collections = await _collectionService.getCollections();
      setState(() {
        _collections = collections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: $e')),
        );
      }
    }
  }

  Future<void> _addCollection() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const AddEditCollectionPage()),
    );

    if (result == true) {
      _loadCollections();
    }
  }

  Future<void> _editCollection(Collection collection) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditCollectionPage(collection: collection),
      ),
    );

    if (result == true) {
      _loadCollections();
    }
  }

  Future<void> _deleteCollection(Collection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Collection'),
            content: Text(
              'Are you sure you want to delete "${collection.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _collectionService.deleteCollection(collection.id);
        _loadCollections();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${collection.name}"')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting collection: $e')),
          );
        }
      }
    }
  }

  Future<void> _openCollection(Collection collection) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => BoardGameCollectionPage(
              username: collection.bggUsername,
              collectionName: collection.name,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Board Game Collections'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCollection,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_collections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No Collections', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Add your first collection to get started',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addCollection,
              icon: const Icon(Icons.add),
              label: const Text('Add Collection'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                collection.name.isNotEmpty
                    ? collection.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(collection.name),
            subtitle: Text('BGG User: ${collection.bggUsername}'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editCollection(collection);
                    break;
                  case 'delete':
                    _deleteCollection(collection);
                    break;
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
            ),
            onTap: () => _openCollection(collection),
          ),
        );
      },
    );
  }
}
