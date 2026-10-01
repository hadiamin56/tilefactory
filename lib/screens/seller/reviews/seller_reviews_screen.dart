import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_theme.dart';
import '../../../main.dart';
import '../../../repositories/review_repository.dart';

class SellerReviewsScreen extends StatefulWidget {
  const SellerReviewsScreen({super.key});

  @override
  State<SellerReviewsScreen> createState() => _SellerReviewsScreenState();
}

class _SellerReviewsScreenState extends State<SellerReviewsScreen> {
  late Future<ReviewSummary> _summaryFuture;
  late Future<List<Review>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    final sellerId = supabase.auth.currentUser!.id;
    _summaryFuture = ReviewRepository.fetchSummaryForSeller(sellerId);
    _reviewsFuture = ReviewRepository.fetchForSeller(sellerId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Reviews')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FutureBuilder<ReviewSummary>(
            future: _summaryFuture,
            builder: (context, snapshot) {
              final summary = snapshot.data ?? ReviewSummary.empty;
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(summary.count == 0 ? '—' : summary.average.toStringAsFixed(1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                        Row(
                          children: List.generate(5, (i) => Icon(
                                i < summary.average.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 16,
                                color: AppColors.amber,
                              )),
                        ),
                        const SizedBox(height: 2),
                        Text('${summary.count} review${summary.count == 1 ? '' : 's'}', style: const TextStyle(color: AppColors.textGrey, fontSize: 11.5)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final count = summary.starBreakdown[star] ?? 0;
                          final ratio = summary.count == 0 ? 0.0 : count / summary.count;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text('$star', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(value: ratio, minHeight: 6, backgroundColor: AppColors.border, color: AppColors.amber),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<Review>>(
            future: _reviewsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
              }
              final reviews = snapshot.data ?? [];
              if (reviews.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.star_border_rounded, size: 44, color: AppColors.textGrey),
                      SizedBox(height: 10),
                      Text('No reviews yet', style: TextStyle(color: AppColors.textGrey)),
                      SizedBox(height: 4),
                      Text('Reviews appear here once growers rate a delivered order', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                  ),
                );
              }
              return Column(
                children: reviews.map((r) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.soft),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.growerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            Text(DateFormat('d MMM yyyy').format(r.createdAt), style: const TextStyle(color: AppColors.textGrey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 15, color: AppColors.amber))),
                        if (r.comment != null && r.comment!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(r.comment!, style: const TextStyle(fontSize: 13, height: 1.4)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
