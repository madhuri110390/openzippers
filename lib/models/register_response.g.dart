// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterResponse _$RegisterResponseFromJson(Map<String, dynamic> json) =>
    RegisterResponse(
      success: RegisterResponse._parseBool(json['success']),
      message: json['message'] as String?,
      data: json['data'] == null
          ? null
          : RegisterData.fromJson(json['data'] as Map<String, dynamic>),
      errors: json['errors'] as Map<String, dynamic>?,
      posts: json['posts'] as List<dynamic>? ?? const [],
    );

Map<String, dynamic> _$RegisterResponseToJson(RegisterResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'errors': instance.errors,
      'posts': instance.posts,
    };

RegisterData _$RegisterDataFromJson(Map<String, dynamic> json) => RegisterData(
  token: json['token'] as String?,
  tokenType: json['token_type'] as String?,
  user: RegisterUser.fromJson(json['user'] as Map<String, dynamic>),
  posts: (json['posts'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$RegisterDataToJson(RegisterData instance) =>
    <String, dynamic>{
      'token': instance.token,
      'token_type': instance.tokenType,
      'user': instance.user,
      'posts': instance.posts,
    };

RegisterUser _$RegisterUserFromJson(Map<String, dynamic> json) => RegisterUser(
  id: RegisterUser._parseInt(json['id']),
  name: json['name'] as String,
  username: json['username'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatar_url'] as String?,
  coverImageUrl: json['cover_image_url'] as String?,
  mobileNumber: json['mobile_number'] as String?,
  roleId: RegisterUser._parseInt(json['role_id']),
  roleName: json['role_name'] as String?,
  walletAmount: json['wallet_amount'],
  gender: json['gender'] as String?,
  bio: json['bio'] as String?,
  countryId: RegisterUser._parseIntNullable(json['country_id']),
  stateId: RegisterUser._parseIntNullable(json['state_id']),
  cityId: RegisterUser._parseIntNullable(json['city_id']),
  emailVerifiedAt: json['email_verified_at'] as String?,
  createdAt: json['created_at'] as String?,
  isArtist: RegisterUser._parseBoolNullable(json['is_artist']),
  isAdmin: RegisterUser._parseBoolNullable(json['is_admin']),
  isVerified: RegisterUser._parseBoolNullable(json['is_verified']),
);

Map<String, dynamic> _$RegisterUserToJson(RegisterUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'avatar_url': instance.avatarUrl,
      'cover_image_url': instance.coverImageUrl,
      'mobile_number': instance.mobileNumber,
      'role_id': instance.roleId,
      'role_name': instance.roleName,
      'wallet_amount': instance.walletAmount,
      'gender': instance.gender,
      'bio': instance.bio,
      'country_id': instance.countryId,
      'state_id': instance.stateId,
      'city_id': instance.cityId,
      'email_verified_at': instance.emailVerifiedAt,
      'created_at': instance.createdAt,
      'is_artist': instance.isArtist,
      'is_admin': instance.isAdmin,
      'is_verified': instance.isVerified,
    };
