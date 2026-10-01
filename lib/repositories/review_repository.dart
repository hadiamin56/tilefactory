import '../main.dart';

class Review {
  final String id;
  final String growerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.growerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class ReviewSummary {
  final double average;
  final int count;
  final Map<int, int> starBreakdown; // 5 -> count, 4 -> count, ...

  const ReviewSummary({required this.average, required this.count, required this.starBreakdown});

  static const empty = ReviewSummary(average: 0, count: 0, starBreakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0});
}

class ReviewRepository {
  static Future<void> submitReview({
    required String orderId,
    required String sellerId,
    required int rating,
    String? comment,
  }) async {
    final growerId = supabase.auth.currentUser!.id;
    await supabase.from('reviews').insert({
      'order_id': orderId,
      'seller_id': sellerId,
      'grower_id': growerId,
      'rating': rating,
      'comment': comment,
    });
  }

  static Future<bool> hasReview(String orderId) async {
    final row = await supabase.from('reviews').select('id').eq('order_id', orderId).maybeSingle();
    return row != null;
  }

  static Future<List<Review>> fetchForSeller(String sellerId) async {
    final rows = await supabase
        .from('reviews')
        .select('id, rating, comment, created_at, grower_id')
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    final reviewRows = (rows as List).cast<Map<String, dynamic>>();
    final growerIds = reviewRows.map((r) => r['grower_id'] as String).toSet().toList();
    final names = <String, String>{};
    if (growerIds.isNotEmpty) {
      final nameRows = await supabase.from('profiles_public').select('id, full_name').inFilter('id', growerIds);
      for (final row in (nameRows as List)) {
        names[row['id'] as String] = (row['full_name'] as String?) ?? 'Grower';
      }
    }

    return reviewRows
        .map((row) => Review(
              id: row['id'] as String,
              growerName: names[row['grower_id']] ?? 'Grower',
              rating: (row['rating'] as num).toInt(),
              comment: row['comment'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String),
            ))
        .toList();
  }

  static Future<ReviewSummary> fetchSummaryForSeller(String sellerId) async {
    final rows = await supabase.from('reviews').select('rating').eq('seller_id', sellerId);
    final ratings = (rows as List).map((r) => (r['rating'] as num).toInt()).toList();
    if (ratings.isEmpty) return ReviewSummary.empty;

    final breakdown = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in ratings) {
      breakdown[r] = (breakdown[r] ?? 0) + 1;
    }
    final average = ratings.reduce((a, b) => a + b) / ratings.length;
    return ReviewSummary(average: average, count: ratings.length, starBreakdown: breakdown);
  }
}
