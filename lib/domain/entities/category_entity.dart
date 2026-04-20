class CategoryEntity {
  final String? id;
  final String name;
  final String icon; // Icon name as string
  final String color; // Hex color as string
  final bool isDefault;

  CategoryEntity({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryEntity.fromMap(Map<String, dynamic> map) {
    return CategoryEntity(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '0xFF808080',
      isDefault: map['is_default'] == 1 || map['is_default'] == true,
    );
  }
}
