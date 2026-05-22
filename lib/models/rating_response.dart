class RatingResponse {
  final bool success;
  final RatingData data;

  RatingResponse({
    required this.success,
    required this.data,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      success: json['success'] ?? false,
      data: RatingData.fromJson(json['data']),
    );
  }
}

class RatingData {
  final int postId;
  final double averageRating;
  final int totalRatings;
  final dynamic userRating;

  RatingData({
    required this.postId,
    required this.averageRating,
    required this.totalRatings,
    required this.userRating,
  });

  factory RatingData.fromJson(Map<String, dynamic> json) {
    return RatingData(
      postId: json['post_id'] ?? 0,
      // averageRating: (json['average_rating'] ?? 0).toDouble(),
      averageRating:
      double.tryParse(
        json['average_rating'].toString(),
      ) ??
          0.0,
      totalRatings: json['total_ratings'] ?? 0,
      userRating: json['user_rating'],
    );
  }
}