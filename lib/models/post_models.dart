class PostData {
  final int id;
  final String title;
  final String postType;
  final String price;
  final String? image;
  final String? filePath;
  final String? lockedImage;
  final String? duration;

  PostData({
    required this.id,
    required this.title,
    required this.postType,
    required this.price,
    this.image,
    this.filePath,
    this.lockedImage,
    this.duration,
  });

  factory PostData.fromJson(Map<String, dynamic> json) => PostData(
    id: json['id'],
    title: json['title'],
    postType: json['post_type'],
    price: json['price'],
    image: json['image'],
    filePath: json['file_path'],
    lockedImage: json['locked_image'],
    duration: json['duration'],
  );

}

enum PostType { post, song, video, literature }

extension PostTypeExtension on PostType {
  String get apiValue {
    switch (this) {
      case PostType.post:       return 'post';
      case PostType.song:       return 'audio';
      case PostType.video:      return 'video';
      case PostType.literature: return 'literature';
    }
  }
}