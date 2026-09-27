import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());
final productsProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).products(),
);
final productsAdminProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).productsAdmin(),
);

/// The product currently flagged to advertise on Home, if any.
final featuredProductProvider = Provider<Map<String, dynamic>?>((ref) {
  final products = ref.watch(productsProvider).value ?? const [];
  for (final product in products) {
    if (product['isFeatured'] == true) return product;
  }
  return null;
});
