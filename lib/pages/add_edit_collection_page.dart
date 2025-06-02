import 'package:flutter/material.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';

class AddEditCollectionPage extends StatefulWidget {
  final Collection? collection;

  const AddEditCollectionPage({super.key, this.collection});

  @override
  State<AddEditCollectionPage> createState() => _AddEditCollectionPageState();
}

class _AddEditCollectionPageState extends State<AddEditCollectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bggUsernameController = TextEditingController();
  final CollectionService _collectionService = CollectionService();
  bool _isLoading = false;

  bool get _isEditing => widget.collection != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.collection!.name;
      _bggUsernameController.text = widget.collection!.bggUsername;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bggUsernameController.dispose();
    super.dispose();
  }

  Future<void> _saveCollection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final bggUsername = _bggUsernameController.text.trim();

      // Check if name is unique
      final isUnique = await _collectionService.isNameUnique(
        name,
        excludeId: _isEditing ? widget.collection!.id : null,
      );

      if (!isUnique) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A collection with this name already exists'),
            ),
          );
        }
        return;
      }

      if (_isEditing) {
        // Update existing collection
        final updatedCollection = widget.collection!.copyWith(
          name: name,
          bggUsername: bggUsername,
        );
        await _collectionService.updateCollection(updatedCollection);
      } else {
        // Create new collection
        final newCollection = Collection(
          id: _collectionService.generateId(),
          name: name,
          bggUsername: bggUsername,
        );
        await _collectionService.addCollection(newCollection);
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving collection: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_isEditing ? 'Edit Collection' : 'Add Collection'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveCollection,
              child: Text(
                _isEditing ? 'Update' : 'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Collection Name',
                  hintText: 'Enter a unique name for this collection',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a collection name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bggUsernameController,
                decoration: const InputDecoration(
                  labelText: 'BoardGameGeek Username',
                  hintText: 'Enter the BGG username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a BGG username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'About Collections',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Collection names must be unique\n'
                        '• BGG username is used to fetch game data\n'
                        '• Multiple collections can share the same BGG username\n'
                        '• Game data is cached locally to reduce API calls',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCollection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Text(
                          _isEditing
                              ? 'Update Collection'
                              : 'Create Collection',
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
