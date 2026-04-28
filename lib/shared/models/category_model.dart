import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name; // key used in DB (no spaces, lowercase)
  final String displayName; // shown in UI
  final bool isBuiltIn; // built-in categories cannot be deleted

  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    this.isBuiltIn = false,
  });

  @override
  List<Object?> get props => [id, name, displayName, isBuiltIn];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'displayName': displayName,
        'isBuiltIn': isBuiltIn ? 1 : 0,
      };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        displayName: map['displayName'] as String,
        isBuiltIn: (map['isBuiltIn'] as int?) == 1,
      );

  Category copyWith({String? displayName}) => Category(
        id: id,
        name: name,
        displayName: displayName ?? this.displayName,
        isBuiltIn: isBuiltIn,
      );

  // Built-in categories seeded on first run
  static const List<Category> builtIn = [
    Category(id: 'coffee', name: 'coffee', displayName: 'Coffee', isBuiltIn: true),
    Category(id: 'nonCoffee', name: 'nonCoffee', displayName: 'Non-Coffee', isBuiltIn: true),
    Category(id: 'tea', name: 'tea', displayName: 'Tea', isBuiltIn: true),
    Category(id: 'snacks', name: 'snacks', displayName: 'Snacks', isBuiltIn: true),
  ];
}
