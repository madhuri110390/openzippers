class Album {
  final int id;
  final String title;
  final String? coverImage;
  final double? price;
  final bool? isPublic;
  final List<AlbumItem> items;

  Album({
    required this.id,
    required this.title,
    this.coverImage,
    this.price,
    this.isPublic,
    this.items = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      coverImage: json['image'], // ✅ was 'cover_image', correct is 'image'
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      isPublic: json['is_public'],
      items: (json['items'] as List? ?? [])
          .map((e) => AlbumItem.fromJson(e))
          .toList(),
    );
  }

  @override
  String toString() =>
      'Album{id: $id, title: $title, coverImage: $coverImage, price: $price, isPublic: $isPublic, items: ${items.length}}';
}

class AlbumItem {
  final int id;
  final int albumId;
  final int trackableId;
  final String trackableType;
  final int sortOrder;

  AlbumItem({
    required this.id,
    required this.albumId,
    required this.trackableId,
    required this.trackableType,
    required this.sortOrder,
  });

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    return AlbumItem(
      id: json['id'] ?? 0,
      albumId: json['album_id'] ?? 0,
      trackableId: json['trackable_id'] ?? 0,
      trackableType: json['trackable_type'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}