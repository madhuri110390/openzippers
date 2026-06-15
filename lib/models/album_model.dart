class Album {
  final int id;
  final String title;
  final String? coverImage;
  final double? price;
  final bool? isPublic;
  final String? userName;
  final List<AlbumItem> items;

  Album({
    required this.id,
    required this.title,
    this.coverImage,
    this.price,
    this.userName,
    this.isPublic,
    this.items = const [],
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
        coverImage: _fixImageUrl(json['image_url'] ?? json['image']), // image_url is broken for my-albums but correct for public
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      isPublic: json['is_public'],
      userName: json['user']?['name'] ?? json['user_name'],  // add this
      items: (json['items'] as List? ?? [])
          .map((e) => AlbumItem.fromJson(e))
          .toList(),
    );
  }

  @override
  String toString() =>
      'Album{id: $id, title: $title, coverImage: $coverImage, price: $price, isPublic: $isPublic, items: ${items.length}}';
}
// In album_model.dart, outside the Album class
String? _fixImageUrl(String? url) {
  if (url == null) return null;
  const base = 'https://dev-openzippers.s3.us-east-1.amazonaws.com/';
  if (url.contains('${base}https://')) {
    return url.replaceFirst(base, '');
  }
  return url;
}
class AlbumItem {
  final int id;
  final int albumId;
  final int trackableId;
  final String trackableType;
  final int sortOrder;
  final String? title;
  final String? postType;
  final String? fileUrl;   // ADD

  AlbumItem({
    required this.id,
    required this.albumId,
    required this.trackableId,
    required this.trackableType,
    required this.sortOrder,
    this.title,
    this.postType,
    this.fileUrl,           // ADD
  });

  factory AlbumItem.fromJson(Map<String, dynamic> json) {
    return AlbumItem(
      id: json['id'] ?? 0,
      albumId: json['album_id'] ?? 0,
      trackableId: json['trackable_id'] ?? 0,
      trackableType: json['trackable_type'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      title: json['trackable']?['title'],
      postType: json['trackable']?['post_type'],
      fileUrl: json['trackable']?['file_url'],  // ADD
    );
  }
}