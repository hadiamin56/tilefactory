import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

IconData _iconFor(ProductCategory c) {
  switch (c) {
    case ProductCategory.fertilizer:
      return Icons.eco_outlined;
    case ProductCategory.pesticide:
      return Icons.bug_report_outlined;
    case ProductCategory.tool:
      return Icons.build_outlined;
    case ProductCategory.box:
      return Icons.inventory_2_outlined;
    case ProductCategory.other:
      return Icons.category_outlined;
  }
}

Color _colorFor(ProductCategory c) {
  switch (c) {
    case ProductCategory.fertilizer:
      return AppColors.primary;
    case ProductCategory.pesticide:
      return AppColors.amber;
    case ProductCategory.tool:
      return AppColors.blue;
    case ProductCategory.box:
      return AppColors.purple;
    case ProductCategory.other:
      return AppColors.textGrey;
  }
}

/// Image-forward grid tile for the Buy Inputs shop view — a real shopping
/// grid (image on top, details below) instead of a compact row.
class ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const ProductGridCard({super.key, required this.product, required this.onAddToCart, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(product.category);
    final outOfStock = product.stock <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => _placeholder(color),
                      loadingBuilder: (context, child, progress) => progress == null ? child : _placeholder(color),
                    )
                  : _placeholder(color),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(product.sellerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5)),
                  const SizedBox(height: 6),
                  Text('₹${product.price.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 14.5)),
                  Text('/ ${product.unit}', style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: outOfStock
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(9)),
                            child: const Text('Out of Stock', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700, fontSize: 11)),
                          )
                        : ElevatedButton(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
                            ),
                            child: const Text('Add to Cart'),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
        ),
      ),
      child: Center(child: Icon(_iconFor(product.category), color: color, size: 34)),
    );
  }
}
