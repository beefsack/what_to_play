class Collection {
  final String id;
  final String name;
  final String bggUsername;

  const Collection({
    required this.id,
    required this.name,
    required this.bggUsername,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'bggUsername': bggUsername};
  }

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String,
      bggUsername: json['bggUsername'] as String,
    );
  }

  Collection copyWith({String? id, String? name, String? bggUsername}) {
    return Collection(
      id: id ?? this.id,
      name: name ?? this.name,
      bggUsername: bggUsername ?? this.bggUsername,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Collection &&
        other.id == id &&
        other.name == name &&
        other.bggUsername == bggUsername;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ bggUsername.hashCode;

  @override
  String toString() {
    return 'Collection(id: $id, name: $name, bggUsername: $bggUsername)';
  }
}
