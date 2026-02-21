import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/category_entity.dart';
import 'infrastructure_providers.dart';

final categoriesProvider = FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return await repo.getCategories();
});
