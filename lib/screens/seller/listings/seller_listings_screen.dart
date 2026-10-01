import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/product.dart';
import '../../../repositories/listing_repository.dart';

class SellerListingsScreen extends StatefulWidget {
  const SellerListingsScreen({super.key});

  @override
  State<SellerListingsScreen> createState() => _SellerListingsScreenState();
}

class _SellerListingsScreenState extends State<SellerListingsScreen> {
  late Future<List<Map<String, dynamic>>> _listingsFuture;
  String? _filter;
  String _search = '';

  static const _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    _listingsFuture = ListingRepository.fetchMyListings();
  }

  Future<void> _refresh() async {
    setState(() {
      _listingsFuture = ListingRepository.fetchMyListings();
    });
    await _listingsFuture;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.primary;
      case 'out_of_stock':
        return AppColors.red;
      case 'paused':
        return AppColors.textGrey;
      default:
        return AppColors.textGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'out_of_stock':
        return 'Out of Stock';
      case 'paused':
        return 'Paused';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showListingSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Add Listing'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _listingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data ?? [];
            final inStockCount = all.where((l) => (l['stock'] as num).toInt() >= _lowStockThreshold).length;
            final lowStockCount = all.where((l) {
              final stock = (l['stock'] as num).toInt();
              return stock > 0 && stock < _lowStockThreshold;
            }).length;
            final outOfStockCount = all.where((l) => (l['stock'] as num).toInt() == 0).length;

            var listings = _filter == null ? all : all.where((l) => l['status'] == _filter).toList();
            if (_search.trim().isNotEmpty) {
              final q = _search.trim().toLowerCase();
              listings = listings.where((l) => (l['name'] as String).toLowerCase().contains(q)).toList();
            }

            final headerColumn = Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: const InputDecoration(hintText: 'Search your listings...', prefixIcon: Icon(Icons.search, size: 20)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StockCountTile(label: 'In Stock', count: inStockCount, color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Expanded(child: _StockCountTile(label: 'Low Stock', count: lowStockCount, color: AppColors.amber)),
                      const SizedBox(width: 8),
                      Expanded(child: _StockCountTile(label: 'Out of Stock', count: outOfStockCount, color: AppColors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Active', selected: _filter == 'active', onTap: () => setState(() => _filter = 'active')),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Out of Stock', selected: _filter == 'out_of_stock', onTap: () => setState(() => _filter = 'out_of_stock')),
                    ],
                  ),
                ],
              ),
            );
            final filterRow = headerColumn;
            if (all.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textGrey)),
                  SizedBox(height: 12),
                  Center(child: Text('No listings yet — tap "Add Listing" to create one', style: TextStyle(color: AppColors.textGrey))),
                ],
              );
            }
            if (listings.isEmpty) {
              return Column(
                children: [
                  filterRow,
                  const Expanded(child: Center(child: Text('No listings in this filter', style: TextStyle(color: AppColors.textGrey)))),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: listings.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) return filterRow;
                final l = listings[i - 1];
                final status = l['status'] as String;
                final imageUrl = l['image_url'] as String?;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.soft),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: AppColors.primaryLight,
                                child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(
                              '\u20B9${(l['price'] as num).toStringAsFixed(0)} / ${l['unit']} · Stock: ${l['stock']}',
                              style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _showListingSheet(context, existing: l);
                            return;
                          }
                          await ListingRepository.updateListingStatus(l['id'] as String, value);
                          _refresh();
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit Listing')),
                          PopupMenuItem(value: 'active', child: Text('Mark Active')),
                          PopupMenuItem(value: 'paused', child: Text('Pause Listing')),
                          PopupMenuItem(value: 'out_of_stock', child: Text('Mark Out of Stock')),
                        ],
                        icon: const Icon(Icons.more_vert, size: 20),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showListingSheet(BuildContext context, {Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final nameController = TextEditingController(text: isEdit ? existing['name'] as String : '');
    final priceController = TextEditingController(text: isEdit ? (existing['price'] as num).toStringAsFixed(0) : '');
    final unitController = TextEditingController(text: isEdit ? existing['unit'] as String : '');
    final stockController = TextEditingController(text: isEdit ? (existing['stock'] as num).toString() : '');
    final descriptionController = TextEditingController(text: isEdit ? (existing['description'] as String? ?? '') : '');
    ProductCategory category = isEdit
        ? ProductCategory.values.firstWhere((c) => c.name == existing['category'], orElse: () => ProductCategory.fertilizer)
        : ProductCategory.fertilizer;
    bool saving = false;
    Uint8List? pickedBytes;
    String pickedExt = 'jpg';
    final existingImageUrl = isEdit ? existing['image_url'] as String? : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> pickImage() async {
            final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
            if (file == null) return;
            final bytes = await file.readAsBytes();
            setSheetState(() {
              pickedBytes = bytes;
              pickedExt = file.name.contains('.') ? file.name.split('.').last : 'jpg';
            });
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEdit ? 'Edit Listing' : 'Add New Listing', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: pickImage,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: pickedBytes != null
                          ? Image.memory(pickedBytes!, width: 96, height: 96, fit: BoxFit.cover)
                          : (existingImageUrl != null && existingImageUrl.isNotEmpty)
                              ? Image.network(
                                  existingImageUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                                    child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
                                  ),
                                )
                              : Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(16)),
                                  child: const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 28),
                                ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(child: Text(pickedBytes != null ? 'Tap to change photo' : 'Tap to add a photo', style: const TextStyle(color: AppColors.textGrey, fontSize: 12))),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(hintText: 'Product name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProductCategory>(
                  initialValue: category,
                  decoration: const InputDecoration(),
                  items: ProductCategory.values
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name[0].toUpperCase() + c.name.substring(1))))
                      .toList(),
                  onChanged: (v) => setSheetState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(hintText: 'Price (\u20B9)'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(hintText: 'Unit (e.g. 50 Kg)'))),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(controller: stockController, decoration: const InputDecoration(hintText: 'Stock quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, maxLines: 3, decoration: const InputDecoration(hintText: 'Description (optional)')),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final price = double.tryParse(priceController.text.trim());
                            final unit = unitController.text.trim();
                            final stock = int.tryParse(stockController.text.trim()) ?? 0;
                            if (name.isEmpty || price == null || unit.isEmpty) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(content: Text('Fill in name, price and unit')),
                              );
                              return;
                            }
                            setSheetState(() => saving = true);
                            try {
                              String? imageUrl = existingImageUrl;
                              if (pickedBytes != null) {
                                imageUrl = await ListingRepository.uploadListingImage(pickedBytes!, pickedExt);
                              }
                              final description = descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim();
                              if (isEdit) {
                                await ListingRepository.updateListing(
                                  listingId: existing['id'] as String,
                                  name: name,
                                  price: price,
                                  unit: unit,
                                  stock: stock,
                                  category: category,
                                  imageUrl: imageUrl,
                                  description: description,
                                );
                              } else {
                                await ListingRepository.createListing(
                                  name: name,
                                  price: price,
                                  unit: unit,
                                  stock: stock,
                                  category: category,
                                  imageUrl: imageUrl,
                                  description: description,
                                );
                              }
                              if (!mounted) return;
                              Navigator.pop(sheetContext);
                              _refresh();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? 'Listing updated' : 'Listing added')));
                            } catch (e) {
                              setSheetState(() => saving = false);
                              ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(isEdit ? 'Could not update listing' : 'Could not save listing')));
                            }
                          },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(isEdit ? 'Save Changes' : 'Save Listing'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StockCountTile extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StockCountTile({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
          Text(label, style: const TextStyle(color: AppColors.textGrey, fontSize: 10.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primaryLight,
      labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textGrey, fontWeight: FontWeight.w600, fontSize: 12.5),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    );
  }
}