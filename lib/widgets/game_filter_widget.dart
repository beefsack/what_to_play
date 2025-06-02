import 'package:flutter/material.dart';
import '../models/game_filter.dart';

class GameFilterWidget extends StatefulWidget {
  final GameFilter initialFilter;
  final Function(GameFilter) onFilterChanged;

  const GameFilterWidget({
    super.key,
    required this.initialFilter,
    required this.onFilterChanged,
  });

  @override
  State<GameFilterWidget> createState() => _GameFilterWidgetState();
}

class _GameFilterWidgetState extends State<GameFilterWidget> {
  late GameFilter _currentFilter;
  final _playerCountController = TextEditingController();
  final _minTimeController = TextEditingController();
  final _maxTimeController = TextEditingController();
  final _minWeightController = TextEditingController();
  final _maxWeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _updateControllers();
  }

  void _updateControllers() {
    _playerCountController.text = _currentFilter.playerCount?.toString() ?? '';
    _minTimeController.text = _currentFilter.minTime?.toString() ?? '';
    _maxTimeController.text = _currentFilter.maxTime?.toString() ?? '';
    _minWeightController.text = _currentFilter.minWeight?.toString() ?? '';
    _maxWeightController.text = _currentFilter.maxWeight?.toString() ?? '';
  }

  @override
  void dispose() {
    _playerCountController.dispose();
    _minTimeController.dispose();
    _maxTimeController.dispose();
    _minWeightController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final playerCount = int.tryParse(_playerCountController.text);
    final minTime = int.tryParse(_minTimeController.text);
    final maxTime = int.tryParse(_maxTimeController.text);
    final minWeight = double.tryParse(_minWeightController.text);
    final maxWeight = double.tryParse(_maxWeightController.text);

    final newFilter = GameFilter(
      playerCount: playerCount,
      playerCountType: _currentFilter.playerCountType,
      minTime: minTime,
      maxTime: maxTime,
      minWeight: minWeight,
      maxWeight: maxWeight,
    );

    widget.onFilterChanged(newFilter);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    final clearedFilter = GameFilter();
    widget.onFilterChanged(clearedFilter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Games',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Player Count Section
                    const Text(
                      'Player Count',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _playerCountController,
                            decoration: const InputDecoration(
                              labelText: 'Number of players',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<PlayerCountFilterType>(
                            value: _currentFilter.playerCountType,
                            decoration: const InputDecoration(
                              labelText: 'Filter type',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items:
                                PlayerCountFilterType.values.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.toString()),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _currentFilter = _currentFilter.copyWith(
                                    playerCountType: value,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Playing Time Section
                    const Text(
                      'Playing Time (minutes)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _maxTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Maximum',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight Section
                    const Text(
                      'Complexity Weight (1-5)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _minWeightController,
                            decoration: const InputDecoration(
                              labelText: 'Minimum',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _maxWeightController,
                            decoration: const InputDecoration(
                              labelText: 'Maximum',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear Filters'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilter,
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
