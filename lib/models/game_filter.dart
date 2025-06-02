enum PlayerCountFilterType {
  best,
  recommended,
  minMax;

  @override
  String toString() {
    switch (this) {
      case PlayerCountFilterType.best:
        return 'Best';
      case PlayerCountFilterType.recommended:
        return 'Recommended';
      case PlayerCountFilterType.minMax:
        return 'Min/Max';
    }
  }
}

class GameFilter {
  final int? playerCount;
  final PlayerCountFilterType playerCountType;
  final int? minTime;
  final int? maxTime;
  final double? minWeight;
  final double? maxWeight;
  final int? minAge;

  GameFilter({
    this.playerCount,
    this.playerCountType = PlayerCountFilterType.recommended,
    this.minTime,
    this.maxTime,
    this.minWeight,
    this.maxWeight,
    this.minAge,
  });

  bool get hasActiveFilters {
    return playerCount != null ||
        minTime != null ||
        maxTime != null ||
        minWeight != null ||
        maxWeight != null ||
        minAge != null;
  }

  GameFilter copyWith({
    int? playerCount,
    PlayerCountFilterType? playerCountType,
    int? minTime,
    int? maxTime,
    double? minWeight,
    double? maxWeight,
    int? minAge,
    bool clearPlayerCount = false,
    bool clearMinTime = false,
    bool clearMaxTime = false,
    bool clearMinWeight = false,
    bool clearMaxWeight = false,
    bool clearMinAge = false,
  }) {
    return GameFilter(
      playerCount: clearPlayerCount ? null : (playerCount ?? this.playerCount),
      playerCountType: playerCountType ?? this.playerCountType,
      minTime: clearMinTime ? null : (minTime ?? this.minTime),
      maxTime: clearMaxTime ? null : (maxTime ?? this.maxTime),
      minWeight: clearMinWeight ? null : (minWeight ?? this.minWeight),
      maxWeight: clearMaxWeight ? null : (maxWeight ?? this.maxWeight),
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
    );
  }

  GameFilter clear() {
    return GameFilter();
  }

  String getActiveFiltersDescription() {
    final filters = <String>[];

    if (playerCount != null) {
      filters.add('${playerCountType.toString()}: $playerCount players');
    }

    if (minTime != null || maxTime != null) {
      if (minTime != null && maxTime != null) {
        filters.add('Time: $minTime-${maxTime}min');
      } else if (minTime != null) {
        filters.add('Time: ${minTime}min+');
      } else {
        filters.add('Time: ≤${maxTime}min');
      }
    }

    if (minWeight != null || maxWeight != null) {
      if (minWeight != null && maxWeight != null) {
        filters.add(
          'Weight: ${minWeight!.toStringAsFixed(1)}-${maxWeight!.toStringAsFixed(1)}',
        );
      } else if (minWeight != null) {
        filters.add('Weight: ${minWeight!.toStringAsFixed(1)}+');
      } else {
        filters.add('Weight: ≤${maxWeight!.toStringAsFixed(1)}');
      }
    }

    if (minAge != null) {
      filters.add('Age: $minAge+');
    }

    return filters.join(', ');
  }
}
