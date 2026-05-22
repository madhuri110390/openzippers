class MockUser {
  final String name;
  final String username;
  final String avatar;
  final String coverImage;
  final bool isVerified;
  final bool isArtist;
  final String phone;
  final String bio;
  final String type;
  final String country;
  final String state;
  final String city;
  final String gender;
  final DateTime joinedDate;
  final bool isOnline;
  final bool isSubscribed;
  final bool isEmailVerified;

  // ✅ Real IDs from API — used by EditProfileScreen for reliable location matching
  final int? countryId;
  final int? stateId;
  final int? cityId;

  MockUser({
    required this.name,
    required this.username,
    required this.avatar,
    this.coverImage = '',
    this.isVerified = false,
    this.isArtist = false,
    this.phone = '',
    this.bio = 'Creative soul | Content Creator | Tech Enthusiast',
    required this.type,
    this.country = '',
    this.state = '',
    this.city = '',
    this.gender = '',
    DateTime? joinedDate,
    this.isOnline = false,
    this.isSubscribed = false,
    this.isEmailVerified = true,
    this.countryId,
    this.stateId,
    this.cityId,
  }) : joinedDate = joinedDate ?? DateTime(2025, 12, 1);

  String get profileImage => avatar;

  MockUser copyWith({
    String? name,
    String? username,
    String? avatar,
    String? coverImage,
    bool? isVerified,
    bool? isArtist,
    String? phone,
    String? bio,
    String? type,
    String? country,
    String? state,
    String? city,
    String? gender,
    DateTime? joinedDate,
    bool? isOnline,
    bool? isSubscribed,
    bool? isEmailVerified,
    int? countryId,
    int? stateId,
    int? cityId,
  }) {
    return MockUser(
      name: name ?? this.name,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      isVerified: isVerified ?? this.isVerified,
      isArtist: isArtist ?? this.isArtist,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      type: type ?? this.type,
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      joinedDate: joinedDate ?? this.joinedDate,
      isOnline: isOnline ?? this.isOnline,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      countryId: countryId ?? this.countryId,
      stateId: stateId ?? this.stateId,
      cityId: cityId ?? this.cityId,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'username': username,
    'avatar': avatar,
    'coverImage': coverImage,
    'isVerified': isVerified ? 1 : 0,
    'isArtist': isArtist ? 1 : 0,
    'bio': bio,
    'phone': phone,
    'type': type,
    'country': country,
    'state': state,
    'city': city,
    'gender': gender,
    'joinedDate': joinedDate.toIso8601String(),
    'isOnline': isOnline ? 1 : 0,
    'isSubscribed': isSubscribed ? 1 : 0,
    'isEmailVerified': isEmailVerified ? 1 : 0,
    'countryId': countryId,
    'stateId': stateId,
    'cityId': cityId,
  };

  factory MockUser.fromJson(Map<String, dynamic> json) {
    return MockUser(
      name: json['name'],
      username: json['username'],
      avatar: json['avatar'],
      coverImage: json['coverImage'] ?? '',
      isVerified: json['isVerified'] == 1 || json['isVerified'] == true,
      isArtist: json['isArtist'] == 1 || json['isArtist'] == true,
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      type: json['type'],
      country: json['country'] ?? '',
      state: json['state'] ?? '',
      city: json['city'] ?? '',
      gender: json['gender'] ?? '',
      joinedDate: json['joinedDate'] != null
          ? DateTime.parse(json['joinedDate'])
          : DateTime(2025, 12, 1),
      isOnline: json['isOnline'] == 1 || json['isOnline'] == true,
      isSubscribed: json['isSubscribed'] == 1 || json['isSubscribed'] == true,
      isEmailVerified:
      json['isEmailVerified'] == 1 || json['isEmailVerified'] == true,
      // ✅ Persist IDs across sessions
      countryId: json['countryId'] as int?,
      stateId: json['stateId'] as int?,
      cityId: json['cityId'] as int?,
    );
  }

  /// ✅ Build a MockUser directly from your API's RegisterUser
  factory MockUser.fromRegisterUser(dynamic registerUser, {String type = 'follower'}) {
    return MockUser(
      name:           registerUser.name ?? '',
      username:       registerUser.username ?? '',
      avatar:         registerUser.avatarUrl ?? '',
      coverImage:     registerUser.coverImageUrl ?? '',
      isVerified:     registerUser.isVerified ?? false,
      isArtist:       registerUser.isArtist ?? false,
      phone:          registerUser.mobileNumber ?? '',
      bio:            registerUser.bio ?? '',
      type:           type,
      gender:         registerUser.gender ?? 'Female',
      // Store IDs directly — names will be resolved by EditProfileScreen
      countryId:      registerUser.countryId,
      stateId:        registerUser.stateId,
      cityId:         registerUser.cityId,
      // Name strings left as empty — EditProfileScreen resolves from API
      country:        '',
      state:          '',
      city:           '',
      isEmailVerified: registerUser.emailVerifiedAt != null,
    );
  }
}

class MockCommunity {
  static List<MockUser> generateUsers() {
    return [];
  }

  static List<Map<String, dynamic>> generatePosts(List<MockUser> users) {
    return [];
  }
}

class MockData {
  static List<MockUser> users = MockCommunity.generateUsers();
}