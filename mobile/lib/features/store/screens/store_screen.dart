import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/resources/app_colors.dart';
import '../../../core/resources/app_icons.dart';
import '../../../core/resources/app_sizes.dart';
import '../../../core/resources/app_strings.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/nav_debounce.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/jbb_button.dart';
import '../../../core/widgets/jbb_card.dart';
import '../../../core/widgets/jbb_empty_state.dart';
import '../../../core/widgets/jbb_loading.dart';
import '../../../core/widgets/page_content.dart';
import '../../../data/services/stripe_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
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
      showMessage(context, AppStrings.chooseASizeFirst);
      return;
    }
    setState(() => busyProductId = id);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null || authUser.isAnonymous) {
        await ref.read(authRepositoryProvider).googleSignIn();
        if (mounted) {
          showMessage(context, AppStrings.signedInTapBuyNowAgainTo);
        }
        return;
      }
      final message = await stripe.purchaseProduct(id, size: selectedSize[id]);
      if (mounted) showMessage(context, message);
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          e is FormatException ? e.message : friendlyError(e),
        );
      }
    } finally {
      if (mounted) setState(() => busyProductId = null);
    }
  }

  Widget productCard(Map<String, dynamic> product, bool isAdmin) {
    final discountPercent =
        (product['discountPercent'] as num?)?.toDouble() ?? 0;
    final hasDiscount =
        product['discountActive'] == true && discountPercent > 0;
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
            borderRadius: BorderRadius.circular(AppSizes.radius8),
            child: (product['imageUrl'] ?? '').isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: product['imageUrl'],
                    width: AppSizes.productThumbnailSize,
                    height: AppSizes.productThumbnailSize,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const _ProductPlaceholder(),
                  )
                : const _ProductPlaceholder(),
          ),
          const SizedBox(width: AppSizes.s14),
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
                          fontSize: AppSizes.font16,
                        ),
                      ),
                    ),
                    if (isAdmin && product['isActive'] != true)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSizes.s8),
                        child: Text(
                          AppStrings.uiHidden,
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: AppSizes.font11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isAdmin && product['isFeatured'] == true)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSizes.s8),
                        child: Text(
                          AppStrings.uiFeatured,
                          style: TextStyle(
                            color: AppColors.materialRed,
                            fontSize: AppSizes.font11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSizes.s8),
                        child: Text(
                          '${discountPercent.toStringAsFixed(0)}% OFF',
                          style: const TextStyle(
                            color: AppColors.materialGreen,
                            fontSize: AppSizes.font11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if ((product['description'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSizes.s4),
                  Text(
                    product['description'],
                    style: const TextStyle(
                      color: AppColors.grey,
                      fontSize: AppSizes.font13,
                    ),
                    maxLines: AppSizes.cardTextLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSizes.s8),
                if (hasDiscount)
                  Row(
                    children: [
                      Text(
                        '\$${(priceCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: AppSizes.font13,
                          color: AppColors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: AppSizes.s8),
                      Text(
                        '\$${(saleCents / 100).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppSizes.font16,
                          color: AppColors.materialGreen,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    product['priceLabel'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.font16,
                      color: AppColors.materialRed,
                    ),
                  ),
                if (!isAdmin) ...[
                  if (List.from(product['sizes'] ?? const []).isNotEmpty) ...[
                    const SizedBox(height: AppSizes.s8),
                    Wrap(
                      spacing: AppSizes.s6,
                      runSpacing: AppSizes.s6,
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
                  const SizedBox(height: AppSizes.s10),
                  SizedBox(
                    width: double.infinity,
                    child: JbbButton(
                      label: AppStrings.buyNow,
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
            const AppIcon(AppIcons.chevronRight, color: AppColors.grey),
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
      appBar: AppBar(title: const Text(AppStrings.gymStore)),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProductEditorScreen()),
              ),
              icon: const AppIcon(AppIcons.plus),
              label: const Text(AppStrings.addProduct),
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
                      ? AppStrings.uiNoProductsYetTapAddProductToCreate
                      : AppStrings.uiProductsWillAppearHereWhenAvailable,
                );
              }
              return Column(
                children: [
                  for (final product in sorted) productCard(product, isAdmin),
                  if (!isAdmin) ...[
                    const SizedBox(height: AppSizes.s8),
                    TextButton(
                      onPressed: () => context.safeNavigate(AppRoutes.contact),
                      child: const Text(
                        AppStrings.uiQuestionAboutAnOrderContactTheGym,
                      ),
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
    width: AppSizes.productThumbnailSize,
    height: AppSizes.productThumbnailSize,
    color: AppColors.white10,
    child: const AppIcon(AppIcons.shoppingBag, color: AppColors.grey),
  );
}
