import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/page_content.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../data/services/stripe_service.dart';
import '../providers/store_provider.dart';
import 'product_editor_screen.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});
  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  final stripe = StripeService();
  String? busyProductId;
  final Map<String, String> selectedSize = {};

  Future<void> buyNow(Map<String, dynamic> product) async {
    if (busyProductId != null) return;
    final id = product['id'] as String;
    final sizes = List<String>.from(product['sizes'] ?? const []);
    if (sizes.isNotEmpty && selectedSize[id] == null) {
      showMessage(context, 'Choose a size first.');
      return;
    }
    setState(() => busyProductId = id);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) showMessage(context, 'Signed in. Tap Buy Now again to complete your order.');
        return;
      }
      final message = await stripe.purchaseProduct(id, size: selectedSize[id]);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) {
        showMessage(context, e is FormatException ? e.message : friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => busyProductId = null);
    }
  }

  Widget productCard(Map<String, dynamic> product, bool isAdmin) {
    final discountPercent =
        (product['discountPercent'] as num?)?.toDouble() ?? 0;
    final hasDiscount = product['discountActive'] == true && discountPercent > 0;
    final priceCents = (product['price'] as num?) ?? 0;
    final saleCents = hasDiscount
        ? (priceCents * (1 - discountPercent / 100)).round()
        : priceCents;
    return JbbCard(
      onTap: isAdmin
          ? () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductEditorScreen(product: product),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (product['imageUrl'] ?? '').isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product['imageUrl'],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const _ProductPlaceholder(),
                  )
                : const _ProductPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isAdmin && product['isActive'] != true)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'HIDDEN',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isAdmin && product['isFeatured'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '${discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((product['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    product['description'],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                if (hasDiscount)
                  Row(
                    children: [
                      Text(
                        '\$${(priceCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${(saleCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    product['priceLabel'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.red,
                    ),
                  ),
                if (!isAdmin) ...[
                  if (List.from(product['sizes'] ?? const []).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final size in List<String>.from(product['sizes']))
                          ChoiceChip(
                            label: Text(size),
                            selected: selectedSize[product['id']] == size,
                            onSelected: (_) => setState(
                              () => selectedSize[product['id']] = size,
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: JbbButton(
                      label: 'Buy Now',
                      busy: busyProductId == product['id'],
                      onPressed: busyProductId == null
                          ? () => buyNow(product)
                          : () {},
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isAdmin)
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(profileProvider).value?['role'] == 'admin';
    final products = ref.watch(
      isAdmin ? productsAdminProvider : productsProvider,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Store')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProductEditorScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
      body: PageContent(
        children: [
          products.when(
            data: (rows) {
              final sorted = [...rows]
                ..sort(
                  (a, b) => (a['sortOrder'] as num? ?? 0).compareTo(
                    b['sortOrder'] as num? ?? 0,
                  ),
                );
              if (sorted.isEmpty) {
                return JbbEmptyState(
                  message: isAdmin
                      ? 'No products yet. Tap Add Product to create your first one.'
                      : 'Products will appear here when available.',
                );
              }
              return Column(
                children: [
                  for (final product in sorted) productCard(product, isAdmin),
                  if (!isAdmin) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.push('/contact'),
                      child: const Text('Question about an order? Contact the gym'),
                    ),
                  ],
                ],
              );
            },
            error: (e, s) => JbbEmptyState(
              message: friendlyError(e),
              onRetry: () => ref.invalidate(
                isAdmin ? productsAdminProvider : productsProvider,
              ),
            ),
            loading: () => const JbbLoading(),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 72,
    height: 72,
    color: Colors.white10,
    child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey),
  );
}
