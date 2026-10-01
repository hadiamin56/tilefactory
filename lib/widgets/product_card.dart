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

class _CategoryPlaceholder extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _CategoryPlaceholder({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.08)],
        ),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, required this.onAddToCart, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(product.category);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _CategoryPlaceholder(icon: _iconFor(product.category), color: color),
                    loadingBuilder: (context, child, progress) => progress == null ? child : _CategoryPlaceholder(icon: _iconFor(product.category), color: color),
                  )
                : _CategoryPlaceholder(icon: _iconFor(product.category), color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.textDark)),
                const SizedBox(height: 3),
                Text(
                  '\u20B9${product.price.toStringAsFixed(0)} / ${product.unit}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (product.stock <= 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppColors.border.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
              child: const Text('Out of Stock', style: TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w700, fontSize: 12)),
            )
          else
            ElevatedButton.icon(
              onPressed: onAddToCart,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
              label: const Text('Add to Cart'),
            ),
        ],
      ),
      ),
    );
  }
}
