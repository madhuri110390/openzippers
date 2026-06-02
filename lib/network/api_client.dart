import 'dart:io';
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import '../models/block_response.dart';
import '../models/comment_response.dart';
import '../models/connection_response.dart';
import '../models/delete_post_response.dart';
import '../models/email_verfication_response.dart';
import '../models/follow_response.dart';
import '../models/like_response.dart';
import '../models/post_checkout_response.dart';
import '../models/rating_response.dart';
import '../models/register_response.dart';
import '../models/location_models.dart';
import '../models/feed_response.dart';
import '../models/search_response.dart';
import '../models/subscription_status_response.dart';
import '../models/support_contact_response.dart';
import '../models/verification_response.dart';
import '../models/wallet_response.dart';
part 'api_client.g.dart';

@RestApi(baseUrl: "https://openzippers.com/api/v1/")
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl}) = _ApiClient;

  //register
  @POST("/register")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  @MultiPart()
  Future<RegisterResponse> register({
    @Part(name: 'name') required String name,
    @Part(name: 'username') required String username,
    @Part(name: 'mobile_number') required String mobileNumber,
    @Part(name: 'country_id') required String countryId,
    @Part(name: 'state_id') required String stateId,
    @Part(name: 'city_id') required String cityId,
    @Part(name: 'gender') required String gender,
    @Part(name: 'email') required String email,
    @Part(name: 'password') required String password,
    @Part(name: 'password_confirmation') required String passwordConfirmation,
    @Part(name: 'agree') required String agree,
    @Part(name: 'avatar') File? avatar,
    @Part(name: 'cover_image') File? coverImage,
  });

  //login
  @POST("/login")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> login(@Body() Map<String, dynamic> body);

  //artist user extraction api
  @GET("/user/by-username")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> getUserByUsername({
    @Query("username") required String username,
  });

//user details-feeds
  @GET("/user")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> getUserDetails();

  //logout
  @POST("/logout-all")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> logoutAll();

  //country
  @GET("https://openzippers.com/countries")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<List<Country>> getCountries();
//state
  @GET("https://openzippers.com/api/states")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<List<StateModel>> getStates({
    @Query("country_id") required String countryId,
  });

  //city
  @GET("https://openzippers.com/cities")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<List<CityModel>> getCities({
    @Query("state_id") required String stateId,
  });

  //update password
  @PUT("/settings/password")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> changePassword(@Body() Map<String, dynamic> body);

  //create post
  @POST("zippfans/posts")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  @MultiPart()
  Future<RegisterResponse> createPost({
    @Part(
        name: 'post_type') required String postType, // "post","video","song","literature"
    @Part(name: 'title') required String title,
    @Part(name: 'body') required String body,
    @Part(name: 'language_id') required String languageId,
    @Part(name: 'price') required String price,
    @Part(name: 'fans_status') required String fansStatus,
    @Part(name: 'image') File? image, // for post_type = "post"
    @Part(name: 'video') File? video, // for post_type = "video"
    @Part(name: 'audio') File? song, // for post_type = "song"
    @Part(name: 'literature') File? literature, // for post_type = "literature"
  });

//profile
  @GET("users/{id}")
  @Headers(<String, dynamic>{"Accept": "application/json"})
  Future<RegisterResponse> getUserById(@Path("id") int id,
      );

  //status offline/online
  @GET("/presence")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RegisterResponse> getPresence();

  // home page feeds
  @GET("zippfans/feed")
  @Headers(<String, dynamic>{"Accept": "application/json"})
  Future<FeedResponse> getFeed({
    @Query("page") int page = 1,
    @Query("tab") String tab = 'main',
  });

  //edit profile 
  @PUT("zippfans/profile")
  @Headers(<String, dynamic>{"Accept": "application/json",})
  Future<RegisterResponse> updateProfile(@Body() Map<String, dynamic> body,);

  //forgot password email reset link
  @POST("https://openzippers.com/api/v1/forgot-password")
  @Headers(<String, dynamic>{"Accept": "application/json"})
  Future<dynamic> forgotPassword(@Body() Map<String, dynamic> body);

  // reset password — called after user taps link in email (token from deep link)
  @POST("https://openzippers.com/api/v1/reset-password")
  @Headers(<String, dynamic>{"Accept": "application/json"})
  Future<dynamic> resetPassword(@Body() Map<String, dynamic> body);


//like / unlike post
  @POST("zippfans/likes/post")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<LikeResponse> toggleLike(@Body() Map<String, dynamic> body);
  
  //comments
@POST("zippfans/comments")
@Headers(<String,dynamic>{
  "Accept": "application/json",
})
Future<CommentResponse> postComment(@Body() Map<String, dynamic> body);

//delete post
  @DELETE("zippfans/posts/{postId}")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<DeletePostResponse> deletePost(@Path("postId") int postId);

  //get ratings
  @GET("zippfans/ratings")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RatingResponse> getRatings({
    @Query("post_id") required int postId,
  });

  //followers-following
  @GET("/connections/list")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<ConnectionsResponse> getConnections({
    @Query("username") required String username,
  });

  //post rating
  @POST("zippfans/ratings")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<RatingResponse> submitRating(
      @Body() Map<String, dynamic> body,
      );

  // support contact
  @POST("support/contact")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<SupportContactResponse> submitSupportContact(
      @Body() Map<String, dynamic> body,
      );

  // global search
  @GET("zippfans/search/global")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<SearchResponse> globalSearch({
    @Query("q") required String query,
  });

  // block/unblock user
  @POST("zippfans/users/block-toggle")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<BlockResponse> toggleBlock(
      @Body() Map<String, dynamic> body,
      );

  // follow/unfollow user
  @POST("zippfans/users/follow-toggle")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<FollowResponse> toggleFollow(
      @Body() Map<String, dynamic> body,
      );
  @GET("/user/wallet")
  Future<WalletResponse> getWalletBalance();

  @GET("/zippfans/subscriptions/status")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<SubscriptionStatusResponse>
  getSubscriptionStatus({
    @Query("artist_id")
    required int artistId,
  });
// creator verification
  @POST("zippfans/creator/verification-documents")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  @MultiPart()
  Future<VerificationResponse> uploadVerificationDocuments({
    @Part(name: 'government_id_front')
    required File governmentIdFront,

    @Part(name: 'government_id_back')
    required File governmentIdBack,

    @Part(name: 'passport_photo')
    required File passportPhoto,
  });

  // email verification send
  @POST("zippfans/verification/email/send")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<EmailVerificationResponse> sendVerificationEmail();

  // Paid Post Checkout
  @POST("zippfans/payments/post/checkout")
  @Headers(<String, dynamic>{
    "Accept": "application/json",
  })
  Future<PostCheckoutResponse> createPostCheckout(
      @Body() Map<String, dynamic> body,
      );
}
