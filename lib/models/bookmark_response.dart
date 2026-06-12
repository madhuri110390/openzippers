class BookmarkResponse {
  final bool isBookmarked;

  BookmarkResponse({required this.isBookmarked});

  factory BookmarkResponse.fromJson(Map<String, dynamic> json) {
    return BookmarkResponse(
      isBookmarked: json['is_bookmarked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'is_bookmarked': isBookmarked};
}