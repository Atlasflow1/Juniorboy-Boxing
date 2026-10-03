import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());
final productsProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).products(),
);
final productsAdminProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).productsAdmin(),
);

/// All products flagged to advertise on Home, shown as a sliding banner.
final featuredProductsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final products = ref.watch(productsProvider).value ?? const [];
  return products.where((p) => p['isFeatured'] == true).toList();
});
