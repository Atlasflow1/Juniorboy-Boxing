import 'dart:io';

import '../../../core/services/stripe_service.dart';
import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'product_model.dart';
import 'product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this.source, this.stripe);
  final ProductRemoteDataSource source;
  final StripeService stripe;

  @override
  String newId() => source.newId();
  @override
  Stream<List<Product>> products() => source.products().map(
    (rows) => rows.map<Product>(ProductModel.fromMap).toList(),
  );
  @override
  Stream<List<Product>> productsAdmin() => source.productsAdmin().map(
    (rows) => rows.map<Product>(ProductModel.fromMap).toList(),
  );
  @override
  Future<String> uploadImage(String id, int index, File file) =>
      source.uploadImage(id, index, file);
  @override
  Future<void> save(String id, Map<String, dynamic> values) =>
      source.save(id, values);
  @override
  Future<void> delete(String id) => source.delete(id);
  @override
  Future<String> purchaseProduct(String id, {String? size}) =>
      stripe.purchaseProduct(id, size: size);
}
