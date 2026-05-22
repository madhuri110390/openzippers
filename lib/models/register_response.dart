import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

part 'register_response.g.dart';

@JsonSerializable()
class RegisterResponse {
  @JsonKey(fromJson: _parseBool)
  final bool success;
  final String? message;
  final RegisterData? data;
  final Map<String, dynamic>? errors;
  final List<dynamic> posts;

  RegisterResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
    this.posts = const [],
  });

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    final bool success = json.containsKey('success')
        ? _parseBool(json['success'])
        : (json.containsKey('user') || json.containsKey('posts'));

    RegisterData? data;
    try {
      if (json.containsKey('data') && json['data'] != null) {
        final d = json['data'];
        if (d is Map<String, dynamic>) {
          data = RegisterData.fromJson(d);
        }
      } else if (json.containsKey('user') && json['user'] != null) {
        data = RegisterData.fromJson(json);
      }
    } catch (e) {
      debugPrint('RegisterResponse.fromJson data parse error: $e');
      data = null;
    }

    Map<String, dynamic>? errors;
    try {
      final raw = json['errors'];
      if (raw is Map) {
        errors = Map<String, dynamic>.from(raw);
      }
    } catch (_) {}

    return RegisterResponse(
      success: success,
      message: json['message'] as String?,
      data: data,
      errors: errors,
      posts: json['posts'] != null
          ? List<Map<String, dynamic>>.from(json['posts'])
          : [],

    );
  }

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}

@JsonSerializable()
class RegisterData {
  final String? token;
  @JsonKey(name: 'token_type')
  final String? tokenType;
  final RegisterUser user;
  final List<Map<String, dynamic>>? posts;

  RegisterData({
    this.token,
    this.tokenType,
    required this.user,
    this.posts,
  });

  factory RegisterData.fromJson(Map<String, dynamic> json) {
    final data = _$RegisterDataFromJson(json);
    return RegisterData(
      token: data.token,
      tokenType: data.tokenType,
      user: data.user,
      posts: json['posts'] != null
          ? List<Map<String, dynamic>>.from(json['posts'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$RegisterDataToJson(this);
}

@JsonSerializable()
class RegisterUser {
  @JsonKey(fromJson: _parseInt)
  final int id;
  final String name;
  final String username;
  final String email;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'mobile_number')
  final String? mobileNumber;
  @JsonKey(name: 'role_id', fromJson: _parseInt)
  final int roleId;
  @JsonKey(name: 'role_name')
  final String? roleName;
  @JsonKey(name: 'wallet_amount')
  final dynamic walletAmount;
  final String? gender;
  final String? bio;
  @JsonKey(name: 'country_id', fromJson: _parseIntNullable)
  final int? countryId;
  @JsonKey(name: 'state_id', fromJson: _parseIntNullable)
  final int? stateId;
  @JsonKey(name: 'city_id', fromJson: _parseIntNullable)
  final int? cityId;
  @JsonKey(name: 'email_verified_at')
  final String? emailVerifiedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'is_artist', fromJson: _parseBoolNullable)
  final bool? isArtist;
  @JsonKey(name: 'is_admin', fromJson: _parseBoolNullable)
  final bool? isAdmin;
  @JsonKey(name: 'is_verified', fromJson: _parseBoolNullable)
  final bool? isVerified;

  RegisterUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.coverImageUrl,
    this.mobileNumber,
    required this.roleId,
    this.roleName,
    this.walletAmount,
    this.gender,
    this.bio,
    this.countryId,
    this.stateId,
    this.cityId,
    this.emailVerifiedAt,
    this.createdAt,
    this.isArtist,
    this.isAdmin,
    this.isVerified,
  });

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static int? _parseIntNullable(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static bool? _parseBoolNullable(dynamic value) {
    if (value == null) return null;
    return RegisterResponse._parseBool(value);
  }

  factory RegisterUser.fromJson(Map<String, dynamic> json) =>
      _$RegisterUserFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterUserToJson(this);
}
