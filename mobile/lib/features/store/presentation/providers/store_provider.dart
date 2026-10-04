import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/product_repository_impl.dart';
import '../../data/product_remote_data_source.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../../../../core/services/stripe_service.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ProductRemoteDataSource(), StripeService()),
);
final productsProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).products(),
);
final productsAdminProvider = StreamProvider(
  (ref) => ref.watch(productRepositoryProvider).productsAdmin(),
);

/// The product currently flagged to advertise on Home, if any.
final featuredProductProvider = Provider<Product?>((ref) {
  final products = ref.watch(productsProvider).value ?? const [];
  for (final product in products) {
    if (product.isFeatured == true) return product;
  }
  return null;
});
final featuredProductsProvider = Provider<List<Product>>(
  (ref) => (ref.watch(productsProvider).value ?? const <Product>[])
      .where((p) => p.isFeatured)
      .toList(),
);
