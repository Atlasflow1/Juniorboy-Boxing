import 'dart:io';

import 'product.dart';

abstract class ProductRepository {
  String newId();
  Stream<List<Product>> products();
  Stream<List<Product>> productsAdmin();
  Future<String> uploadImage(String id, int index, File file);
  Future<void> save(String id, Map<String, dynamic> values);
  Future<void> delete(String id);
  Future<String> purchaseProduct(String id, {String? size});
}
