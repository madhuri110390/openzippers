import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fil.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fil'),
    Locale('fr'),
    Locale('hi'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('ms'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('sw'),
    Locale('th'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explore;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @reels.
  ///
  /// In en, this message translates to:
  /// **'Reels'**
  String get reels;

  /// No description provided for @live.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @liveStreams.
  ///
  /// In en, this message translates to:
  /// **'Live Streams'**
  String get liveStreams;

  /// No description provided for @bookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @streaming.
  ///
  /// In en, this message translates to:
  /// **'STREAMING'**
  String get streaming;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @changeFile.
  ///
  /// In en, this message translates to:
  /// **'Change File'**
  String get changeFile;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @follower.
  ///
  /// In en, this message translates to:
  /// **'Follower'**
  String get follower;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @likes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get likes;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @shares.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get shares;

  /// No description provided for @views.
  ///
  /// In en, this message translates to:
  /// **'Views'**
  String get views;

  /// No description provided for @reads.
  ///
  /// In en, this message translates to:
  /// **'Reads'**
  String get reads;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @song.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get song;

  /// No description provided for @literature.
  ///
  /// In en, this message translates to:
  /// **'Literature'**
  String get literature;

  /// No description provided for @reel.
  ///
  /// In en, this message translates to:
  /// **'Reel'**
  String get reel;

  /// No description provided for @genre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get genre;

  /// No description provided for @selectGenre.
  ///
  /// In en, this message translates to:
  /// **'Select Genre'**
  String get selectGenre;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @uploadVideo.
  ///
  /// In en, this message translates to:
  /// **'Upload Video'**
  String get uploadVideo;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Enter Text'**
  String get enterText;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchPlaceholder;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCart;

  /// No description provided for @removeFromCart.
  ///
  /// In en, this message translates to:
  /// **'Remove from Cart'**
  String get removeFromCart;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @enterTitleError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Title'**
  String get enterTitleError;

  /// No description provided for @selectLanguageError.
  ///
  /// In en, this message translates to:
  /// **'Please select a language'**
  String get selectLanguageError;

  /// No description provided for @contentProcessingError.
  ///
  /// In en, this message translates to:
  /// **'Error processing content. Please try again.'**
  String get contentProcessingError;

  /// No description provided for @uploadPdfError.
  ///
  /// In en, this message translates to:
  /// **'Please upload a PDF file for Literature post'**
  String get uploadPdfError;

  /// No description provided for @pdfFileNotExistError.
  ///
  /// In en, this message translates to:
  /// **'Selected PDF file does not exist. Please try uploading again.'**
  String get pdfFileNotExistError;

  /// No description provided for @notPdfError.
  ///
  /// In en, this message translates to:
  /// **'Please upload a PDF file. Selected file is not a PDF.'**
  String get notPdfError;

  /// No description provided for @pdfValidationError.
  ///
  /// In en, this message translates to:
  /// **'Error validating PDF file. Please try uploading again.'**
  String get pdfValidationError;

  /// No description provided for @writeContentError.
  ///
  /// In en, this message translates to:
  /// **'Please write content'**
  String get writeContentError;

  /// No description provided for @fileNotExistError.
  ///
  /// In en, this message translates to:
  /// **'Selected file does not exist. Please try uploading again.'**
  String get fileNotExistError;

  /// No description provided for @fileValidationError.
  ///
  /// In en, this message translates to:
  /// **'Error validating file. Please try uploading again.'**
  String get fileValidationError;

  /// No description provided for @uploadCoverImageError.
  ///
  /// In en, this message translates to:
  /// **'Please upload a cover image'**
  String get uploadCoverImageError;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFrench;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audio;

  /// No description provided for @imageLabel.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get imageLabel;

  /// No description provided for @videoLabel.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get videoLabel;

  /// No description provided for @audioLabel.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get audioLabel;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResults;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get somethingWrong;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @newFollower.
  ///
  /// In en, this message translates to:
  /// **'New Follower'**
  String get newFollower;

  /// No description provided for @likedPost.
  ///
  /// In en, this message translates to:
  /// **'Liked your post'**
  String get likedPost;

  /// No description provided for @commentedPost.
  ///
  /// In en, this message translates to:
  /// **'Commented on your post'**
  String get commentedPost;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @writeCaption.
  ///
  /// In en, this message translates to:
  /// **'Write a caption...'**
  String get writeCaption;

  /// No description provided for @addLocation.
  ///
  /// In en, this message translates to:
  /// **'Add Location'**
  String get addLocation;

  /// No description provided for @tagPeople.
  ///
  /// In en, this message translates to:
  /// **'Tag People'**
  String get tagPeople;

  /// No description provided for @viewMore.
  ///
  /// In en, this message translates to:
  /// **'View more'**
  String get viewMore;

  /// No description provided for @viewLess.
  ///
  /// In en, this message translates to:
  /// **'View less'**
  String get viewLess;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// No description provided for @suggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get suggested;

  /// No description provided for @forYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share Post'**
  String get sharePost;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get confirmLogout;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get enableNotifications;

  /// No description provided for @postLikes.
  ///
  /// In en, this message translates to:
  /// **'Post Likes'**
  String get postLikes;

  /// No description provided for @postComments.
  ///
  /// In en, this message translates to:
  /// **'Post Comments'**
  String get postComments;

  /// No description provided for @manageAccount.
  ///
  /// In en, this message translates to:
  /// **'Manage Account'**
  String get manageAccount;

  /// No description provided for @manageAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account preferences, notifications, and privacy settings.'**
  String get manageAccountSubtitle;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @quickAmounts.
  ///
  /// In en, this message translates to:
  /// **'Quick amounts'**
  String get quickAmounts;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @walletTransactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get walletTransactionHistory;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

  /// No description provided for @subscriptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Subscription History'**
  String get subscriptionHistory;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @getInTouch.
  ///
  /// In en, this message translates to:
  /// **'Get in touch'**
  String get getInTouch;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @learnBasics.
  ///
  /// In en, this message translates to:
  /// **'Learn the basics'**
  String get learnBasics;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating an Account'**
  String get creatingAccount;

  /// No description provided for @creatingAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to set up your profile and account'**
  String get creatingAccountDesc;

  /// No description provided for @exploringPlatform.
  ///
  /// In en, this message translates to:
  /// **'Exploring the Platform'**
  String get exploringPlatform;

  /// No description provided for @exploringPlatformDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover features and tools available to you'**
  String get exploringPlatformDesc;

  /// No description provided for @setupProfile.
  ///
  /// In en, this message translates to:
  /// **'Setting up Profile'**
  String get setupProfile;

  /// No description provided for @setupProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize your profile to stand out'**
  String get setupProfileDesc;

  /// No description provided for @currentlyDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get currentlyDark;

  /// No description provided for @currentlyLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get currentlyLight;

  /// No description provided for @liveNow.
  ///
  /// In en, this message translates to:
  /// **'Live Now'**
  String get liveNow;

  /// No description provided for @goLive.
  ///
  /// In en, this message translates to:
  /// **'Go Live'**
  String get goLive;

  /// No description provided for @startLiveStream.
  ///
  /// In en, this message translates to:
  /// **'Start Live Stream'**
  String get startLiveStream;

  /// No description provided for @startStreaming.
  ///
  /// In en, this message translates to:
  /// **'Start Streaming'**
  String get startStreaming;

  /// No description provided for @startStream.
  ///
  /// In en, this message translates to:
  /// **'Start Stream'**
  String get startStream;

  /// No description provided for @endStream.
  ///
  /// In en, this message translates to:
  /// **'End Stream'**
  String get endStream;

  /// No description provided for @youAreLive.
  ///
  /// In en, this message translates to:
  /// **'You are LIVE'**
  String get youAreLive;

  /// No description provided for @streamTitle.
  ///
  /// In en, this message translates to:
  /// **'Stream Title'**
  String get streamTitle;

  /// No description provided for @streamTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Stream title is required'**
  String get streamTitleRequired;

  /// No description provided for @configureStreamSettings.
  ///
  /// In en, this message translates to:
  /// **'Configure Stream Settings'**
  String get configureStreamSettings;

  /// No description provided for @joinStreamById.
  ///
  /// In en, this message translates to:
  /// **'Join Stream by ID'**
  String get joinStreamById;

  /// No description provided for @joinStream.
  ///
  /// In en, this message translates to:
  /// **'Join Stream'**
  String get joinStream;

  /// No description provided for @allStreamsCleared.
  ///
  /// In en, this message translates to:
  /// **'All streams cleared'**
  String get allStreamsCleared;

  /// No description provided for @onlyArtistsCanStream.
  ///
  /// In en, this message translates to:
  /// **'Only artists can start a stream'**
  String get onlyArtistsCanStream;

  /// No description provided for @streamLocked.
  ///
  /// In en, this message translates to:
  /// **'Stream Locked'**
  String get streamLocked;

  /// No description provided for @streamRequiresPayment.
  ///
  /// In en, this message translates to:
  /// **'This stream requires payment'**
  String get streamRequiresPayment;

  /// No description provided for @oneTimePayment.
  ///
  /// In en, this message translates to:
  /// **'One-time payment'**
  String get oneTimePayment;

  /// No description provided for @unlockStream.
  ///
  /// In en, this message translates to:
  /// **'Unlock Stream'**
  String get unlockStream;

  /// No description provided for @payAndUnlock.
  ///
  /// In en, this message translates to:
  /// **'Pay & Unlock'**
  String get payAndUnlock;

  /// No description provided for @subscribeToArtist.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Artist'**
  String get subscribeToArtist;

  /// No description provided for @subscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscribe;

  /// No description provided for @chatLocked.
  ///
  /// In en, this message translates to:
  /// **'Chat Locked'**
  String get chatLocked;

  /// No description provided for @unlockStreamToChat.
  ///
  /// In en, this message translates to:
  /// **'Unlock stream to chat'**
  String get unlockStreamToChat;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @beFirstToSayHello.
  ///
  /// In en, this message translates to:
  /// **'Be the first to say hello!'**
  String get beFirstToSayHello;

  /// No description provided for @streamAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Stream Analytics'**
  String get streamAnalytics;

  /// No description provided for @cameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get cameraOff;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @pleaseEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get pleaseEnterValidAmount;

  /// No description provided for @amountCleared.
  ///
  /// In en, this message translates to:
  /// **'Amount cleared'**
  String get amountCleared;

  /// No description provided for @balanceCleared.
  ///
  /// In en, this message translates to:
  /// **'Balance cleared'**
  String get balanceCleared;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'\$'**
  String get currencySymbol;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @transactionHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get transactionHistory;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptions;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @manageWallet.
  ///
  /// In en, this message translates to:
  /// **'Manage Wallet'**
  String get manageWallet;

  /// No description provided for @viewPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'View Payment History'**
  String get viewPaymentHistory;

  /// No description provided for @emptyCart.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get emptyCart;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPosts;

  /// No description provided for @noPostsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No posts available'**
  String get noPostsAvailable;

  /// No description provided for @followCreatorsToSeePosts.
  ///
  /// In en, this message translates to:
  /// **'Follow creators to see their posts here'**
  String get followCreatorsToSeePosts;

  /// No description provided for @viewMyPosts.
  ///
  /// In en, this message translates to:
  /// **'View My Posts'**
  String get viewMyPosts;

  /// No description provided for @exploreCreators.
  ///
  /// In en, this message translates to:
  /// **'Explore Creators'**
  String get exploreCreators;

  /// No description provided for @myPosts.
  ///
  /// In en, this message translates to:
  /// **'My Posts'**
  String get myPosts;

  /// No description provided for @allPosts.
  ///
  /// In en, this message translates to:
  /// **'All Posts'**
  String get allPosts;

  /// No description provided for @bookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// No description provided for @browsePosts.
  ///
  /// In en, this message translates to:
  /// **'Browse Posts'**
  String get browsePosts;

  /// No description provided for @createFirstPost.
  ///
  /// In en, this message translates to:
  /// **'Create your first post'**
  String get createFirstPost;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @myAlbums.
  ///
  /// In en, this message translates to:
  /// **'My Albums'**
  String get myAlbums;

  /// No description provided for @createAlbum.
  ///
  /// In en, this message translates to:
  /// **'Create Album'**
  String get createAlbum;

  /// No description provided for @manageAlbumsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your music and albums'**
  String get manageAlbumsSubtitle;

  /// No description provided for @noConnections.
  ///
  /// In en, this message translates to:
  /// **'No connections yet'**
  String get noConnections;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard Changes'**
  String get discardChanges;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get subjectRequired;

  /// No description provided for @messageRequired.
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get messageRequired;

  /// No description provided for @supportRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted!'**
  String get supportRequestSubmitted;

  /// No description provided for @fillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all required fields'**
  String get fillAllRequiredFields;

  /// No description provided for @enterSubject.
  ///
  /// In en, this message translates to:
  /// **'Enter subject'**
  String get enterSubject;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @accountIssues.
  ///
  /// In en, this message translates to:
  /// **'Account Issues'**
  String get accountIssues;

  /// No description provided for @streamingProblems.
  ///
  /// In en, this message translates to:
  /// **'Streaming Problems'**
  String get streamingProblems;

  /// No description provided for @billingQuestions.
  ///
  /// In en, this message translates to:
  /// **'Billing Questions'**
  String get billingQuestions;

  /// No description provided for @technicalSupport.
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get technicalSupport;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @myCart.
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// No description provided for @orderPlacedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully!'**
  String get orderPlacedSuccess;

  /// No description provided for @noItemsInCart.
  ///
  /// In en, this message translates to:
  /// **'No items in cart'**
  String get noItemsInCart;

  /// No description provided for @addItemsToCart.
  ///
  /// In en, this message translates to:
  /// **'Add items to your cart'**
  String get addItemsToCart;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @proceedToPayment.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Payment'**
  String get proceedToPayment;

  /// No description provided for @noLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available'**
  String get noLongerAvailable;

  /// No description provided for @itemNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'This item is no longer available'**
  String get itemNoLongerAvailable;

  /// No description provided for @allItemsNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'All items in your cart are no longer available'**
  String get allItemsNoLongerAvailable;

  /// No description provided for @qty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get qty;

  /// No description provided for @manageConnections.
  ///
  /// In en, this message translates to:
  /// **'Manage Connections'**
  String get manageConnections;

  /// No description provided for @searchConnections.
  ///
  /// In en, this message translates to:
  /// **'Search connections...'**
  String get searchConnections;

  /// No description provided for @followBack.
  ///
  /// In en, this message translates to:
  /// **'Follow Back'**
  String get followBack;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No followers yet'**
  String get noFollowersYet;

  /// No description provided for @shareProfileToGetDiscovered.
  ///
  /// In en, this message translates to:
  /// **'Share your profile to get discovered'**
  String get shareProfileToGetDiscovered;

  /// No description provided for @notFollowingAnyone.
  ///
  /// In en, this message translates to:
  /// **'Not following anyone yet'**
  String get notFollowingAnyone;

  /// No description provided for @exploreToFindCreators.
  ///
  /// In en, this message translates to:
  /// **'Explore to find creators'**
  String get exploreToFindCreators;

  /// No description provided for @clearList.
  ///
  /// In en, this message translates to:
  /// **'Clear List'**
  String get clearList;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get nothingHere;

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get allCaughtUp;

  /// No description provided for @likedYourPost.
  ///
  /// In en, this message translates to:
  /// **'liked your post'**
  String get likedYourPost;

  /// No description provided for @commentedOnYourPost.
  ///
  /// In en, this message translates to:
  /// **'commented on your post'**
  String get commentedOnYourPost;

  /// No description provided for @repliedToYourComment.
  ///
  /// In en, this message translates to:
  /// **'replied to your comment'**
  String get repliedToYourComment;

  /// No description provided for @itemAddedToCart.
  ///
  /// In en, this message translates to:
  /// **'Item added to cart'**
  String get itemAddedToCart;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Clear all notifications?'**
  String get clearAllNotifications;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @bookmarkedPosts.
  ///
  /// In en, this message translates to:
  /// **'Bookmarked Posts'**
  String get bookmarkedPosts;

  /// No description provided for @noBookmarkedPosts.
  ///
  /// In en, this message translates to:
  /// **'No bookmarked posts'**
  String get noBookmarkedPosts;

  /// No description provided for @bookmarkPostsToSeeHere.
  ///
  /// In en, this message translates to:
  /// **'Bookmark posts to see them here'**
  String get bookmarkPostsToSeeHere;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search Users'**
  String get searchUsers;

  /// No description provided for @searchPosts.
  ///
  /// In en, this message translates to:
  /// **'Search Posts'**
  String get searchPosts;

  /// No description provided for @searchContent.
  ///
  /// In en, this message translates to:
  /// **'Search Content'**
  String get searchContent;

  /// No description provided for @thisAccountIsPrivate.
  ///
  /// In en, this message translates to:
  /// **'This account is private'**
  String get thisAccountIsPrivate;

  /// No description provided for @startCreatingContent.
  ///
  /// In en, this message translates to:
  /// **'Start creating content to see it here'**
  String get startCreatingContent;

  /// No description provided for @makeItFree.
  ///
  /// In en, this message translates to:
  /// **'Make it Free'**
  String get makeItFree;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @postCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Post created successfully!'**
  String get postCreatedSuccessfully;

  /// No description provided for @selectType.
  ///
  /// In en, this message translates to:
  /// **'Select Type'**
  String get selectType;

  /// No description provided for @uploadCoverImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover Image'**
  String get uploadCoverImage;

  /// No description provided for @coverImage.
  ///
  /// In en, this message translates to:
  /// **'Cover Image'**
  String get coverImage;

  /// No description provided for @rateThisPost.
  ///
  /// In en, this message translates to:
  /// **'Rate this post'**
  String get rateThisPost;

  /// No description provided for @addToBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add to Bookmark'**
  String get addToBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove Bookmark'**
  String get removeBookmark;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @notificationsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Notifications Not Available'**
  String get notificationsNotAvailable;

  /// No description provided for @createNewPost.
  ///
  /// In en, this message translates to:
  /// **'Create New Post'**
  String get createNewPost;

  /// No description provided for @shareContentWithCommunity.
  ///
  /// In en, this message translates to:
  /// **'Share Your Content With The Community'**
  String get shareContentWithCommunity;

  /// No description provided for @chooseType.
  ///
  /// In en, this message translates to:
  /// **'Choose Type'**
  String get chooseType;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Title'**
  String get enterTitle;

  /// No description provided for @readyToPost.
  ///
  /// In en, this message translates to:
  /// **'Ready to Post'**
  String get readyToPost;

  /// No description provided for @audioFile.
  ///
  /// In en, this message translates to:
  /// **'Audio File'**
  String get audioFile;

  /// No description provided for @videoFile.
  ///
  /// In en, this message translates to:
  /// **'Video File'**
  String get videoFile;

  /// No description provided for @reelVideo.
  ///
  /// In en, this message translates to:
  /// **'Reel Video'**
  String get reelVideo;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @imageFile.
  ///
  /// In en, this message translates to:
  /// **'Image File'**
  String get imageFile;

  /// No description provided for @uploadAudio.
  ///
  /// In en, this message translates to:
  /// **'Upload Audio'**
  String get uploadAudio;

  /// No description provided for @uploadReel.
  ///
  /// In en, this message translates to:
  /// **'Upload Reel'**
  String get uploadReel;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @mp3WavUpTo50MB.
  ///
  /// In en, this message translates to:
  /// **'MP3, WAV (Max 50MB)'**
  String get mp3WavUpTo50MB;

  /// No description provided for @mp4AviUpTo500MB.
  ///
  /// In en, this message translates to:
  /// **'MP4, AVI (Max 500MB)'**
  String get mp4AviUpTo500MB;

  /// No description provided for @mp4AviUpTo50MBMax15Sec.
  ///
  /// In en, this message translates to:
  /// **'MP4, AVI (Max 50MB, Max 15s)'**
  String get mp4AviUpTo50MBMax15Sec;

  /// No description provided for @pdfDocxSupported.
  ///
  /// In en, this message translates to:
  /// **'PDF, DOCX Supported'**
  String get pdfDocxSupported;

  /// No description provided for @jpgPngSupported.
  ///
  /// In en, this message translates to:
  /// **'JPG, PNG Supported'**
  String get jpgPngSupported;

  /// No description provided for @pngJpgGifUpTo10MB.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG, GIF (Max 10MB)'**
  String get pngJpgGifUpTo10MB;

  /// No description provided for @uploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload Cover'**
  String get uploadCover;

  /// No description provided for @wordPad.
  ///
  /// In en, this message translates to:
  /// **'Word Pad'**
  String get wordPad;

  /// No description provided for @cropImage.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImage;

  /// No description provided for @imageCroppedReady.
  ///
  /// In en, this message translates to:
  /// **'Image cropped and ready'**
  String get imageCroppedReady;

  /// No description provided for @describeYourPost.
  ///
  /// In en, this message translates to:
  /// **'Describe Your Post...'**
  String get describeYourPost;

  /// No description provided for @noReelsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Reels Available'**
  String get noReelsAvailable;

  /// No description provided for @createOrFollowToSeeReels.
  ///
  /// In en, this message translates to:
  /// **'Create Or Follow To See Reels'**
  String get createOrFollowToSeeReels;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @deletePostConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure You Want To Delete This Post?'**
  String get deletePostConfirm;

  /// No description provided for @videoNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Video Not Available'**
  String get videoNotAvailable;

  /// No description provided for @noWalletTransactions.
  ///
  /// In en, this message translates to:
  /// **'No Wallet Transactions Yet'**
  String get noWalletTransactions;

  /// No description provided for @walletTransactionHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Transaction History Will Appear Here'**
  String get walletTransactionHistoryDesc;

  /// No description provided for @enter4DigitStreamId.
  ///
  /// In en, this message translates to:
  /// **'Enter 4 Digit Stream ID'**
  String get enter4DigitStreamId;

  /// No description provided for @setPrice.
  ///
  /// In en, this message translates to:
  /// **'Set Price'**
  String get setPrice;

  /// No description provided for @streamPoster.
  ///
  /// In en, this message translates to:
  /// **'Stream Poster'**
  String get streamPoster;

  /// No description provided for @noFileChosen.
  ///
  /// In en, this message translates to:
  /// **'No file chosen'**
  String get noFileChosen;

  /// No description provided for @streamDescription.
  ///
  /// In en, this message translates to:
  /// **'Stream Description'**
  String get streamDescription;

  /// No description provided for @liveStream.
  ///
  /// In en, this message translates to:
  /// **'Live Stream'**
  String get liveStream;

  /// No description provided for @noPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'No Payment History'**
  String get noPaymentHistory;

  /// No description provided for @paymentHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Payment History Will Show Up Here'**
  String get paymentHistoryDesc;

  /// No description provided for @dateNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Date Not Available'**
  String get dateNotAvailable;

  /// No description provided for @noSubscriptionsFound.
  ///
  /// In en, this message translates to:
  /// **'No Subscriptions Found'**
  String get noSubscriptionsFound;

  /// No description provided for @subscriptionHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Subscription History Will Appear Here'**
  String get subscriptionHistoryDesc;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @subscriber.
  ///
  /// In en, this message translates to:
  /// **'Subscriber'**
  String get subscriber;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright'**
  String get copyright;

  /// No description provided for @publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing'**
  String get publishing;

  /// No description provided for @getCertificate.
  ///
  /// In en, this message translates to:
  /// **'Get Certificate'**
  String get getCertificate;

  /// No description provided for @requestCertificate.
  ///
  /// In en, this message translates to:
  /// **'Request Certificate'**
  String get requestCertificate;

  /// No description provided for @artistName.
  ///
  /// In en, this message translates to:
  /// **'Artist Name'**
  String get artistName;

  /// No description provided for @writtenBy.
  ///
  /// In en, this message translates to:
  /// **'Written By'**
  String get writtenBy;

  /// No description provided for @idCard.
  ///
  /// In en, this message translates to:
  /// **'ID Card'**
  String get idCard;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No File Selected'**
  String get noFileSelected;

  /// No description provided for @iAcceptTerms.
  ///
  /// In en, this message translates to:
  /// **'I Accept Terms'**
  String get iAcceptTerms;

  /// No description provided for @certificate.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get certificate;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndConditions;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @publishedContent.
  ///
  /// In en, this message translates to:
  /// **'Published Content'**
  String get publishedContent;

  /// No description provided for @requestPublishing.
  ///
  /// In en, this message translates to:
  /// **'Request Publishing'**
  String get requestPublishing;

  /// No description provided for @publishingSubTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish your content'**
  String get publishingSubTitle;

  /// No description provided for @publishingContent.
  ///
  /// In en, this message translates to:
  /// **'Publishing Content'**
  String get publishingContent;

  /// No description provided for @enterContentToPublish.
  ///
  /// In en, this message translates to:
  /// **'Enter Content To Publish'**
  String get enterContentToPublish;

  /// No description provided for @uploadFiles.
  ///
  /// In en, this message translates to:
  /// **'Upload Files'**
  String get uploadFiles;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @artistNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Artist Name Is Required'**
  String get artistNameRequired;

  /// No description provided for @writerNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Writer Name Is Required'**
  String get writerNameRequired;

  /// No description provided for @idCardRequired.
  ///
  /// In en, this message translates to:
  /// **'ID Card Is Required'**
  String get idCardRequired;

  /// No description provided for @acceptTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'You Must Accept The Terms'**
  String get acceptTermsRequired;

  /// No description provided for @enterWriterName.
  ///
  /// In en, this message translates to:
  /// **'Enter Writer Name'**
  String get enterWriterName;

  /// No description provided for @contentSubmittedCopyright.
  ///
  /// In en, this message translates to:
  /// **'Content Submitted For Copyright'**
  String get contentSubmittedCopyright;

  /// No description provided for @contentSubmittedPublishing.
  ///
  /// In en, this message translates to:
  /// **'Content Submitted For Publishing'**
  String get contentSubmittedPublishing;

  /// No description provided for @iAcceptThe.
  ///
  /// In en, this message translates to:
  /// **'I Accept The'**
  String get iAcceptThe;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @messagingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messaging Coming Soon'**
  String get messagingComingSoon;

  /// No description provided for @youHaveBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'You Have Blocked This User'**
  String get youHaveBlockedUser;

  /// No description provided for @unblockToSeePosts.
  ///
  /// In en, this message translates to:
  /// **'Unblock Them To See Their Posts'**
  String get unblockToSeePosts;

  /// No description provided for @unblockBtn.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockBtn;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OpenZippers'**
  String get appName;

  /// No description provided for @followRef.
  ///
  /// In en, this message translates to:
  /// **'Follow Reference'**
  String get followRef;

  /// No description provided for @noPostsFoundCategory.
  ///
  /// In en, this message translates to:
  /// **'No Posts Found In This Category'**
  String get noPostsFoundCategory;

  /// No description provided for @mediaPreviewNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Media Preview Not Available'**
  String get mediaPreviewNotAvailable;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @dots.
  ///
  /// In en, this message translates to:
  /// **'...'**
  String get dots;

  /// No description provided for @dayShort.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get dayShort;

  /// No description provided for @hourShort.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourShort;

  /// No description provided for @minuteShort.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minuteShort;

  /// No description provided for @playAlbum.
  ///
  /// In en, this message translates to:
  /// **'Play Album'**
  String get playAlbum;

  /// No description provided for @editAlbum.
  ///
  /// In en, this message translates to:
  /// **'Edit Album'**
  String get editAlbum;

  /// No description provided for @deleteAlbum.
  ///
  /// In en, this message translates to:
  /// **'Delete Album'**
  String get deleteAlbum;

  /// No description provided for @albumTitle.
  ///
  /// In en, this message translates to:
  /// **'Album Title'**
  String get albumTitle;

  /// No description provided for @enterAlbumTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Album Title'**
  String get enterAlbumTitle;

  /// No description provided for @albumCover.
  ///
  /// In en, this message translates to:
  /// **'Album Cover'**
  String get albumCover;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File Selected'**
  String get fileSelected;

  /// No description provided for @pngJpgGifUpTo2MB.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG, GIF (Max 2MB)'**
  String get pngJpgGifUpTo2MB;

  /// No description provided for @selectTracks.
  ///
  /// In en, this message translates to:
  /// **'Select Tracks'**
  String get selectTracks;

  /// No description provided for @addTracksToAlbum.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks To Album'**
  String get addTracksToAlbum;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @albumUpdated.
  ///
  /// In en, this message translates to:
  /// **'Album Updated'**
  String get albumUpdated;

  /// No description provided for @albumDeleted.
  ///
  /// In en, this message translates to:
  /// **'Album Deleted'**
  String get albumDeleted;

  /// No description provided for @deselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @noAlbumsYet.
  ///
  /// In en, this message translates to:
  /// **'No Albums Yet'**
  String get noAlbumsYet;

  /// No description provided for @createFirstAlbumDesc.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Music Album'**
  String get createFirstAlbumDesc;

  /// No description provided for @createYourFirstAlbum.
  ///
  /// In en, this message translates to:
  /// **'Create Your First Album'**
  String get createYourFirstAlbum;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown Album'**
  String get unknownAlbum;

  /// No description provided for @songsPlural.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get songsPlural;

  /// No description provided for @videosPlural.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get videosPlural;

  /// No description provided for @noMediaFound.
  ///
  /// In en, this message translates to:
  /// **'No Media Found'**
  String get noMediaFound;

  /// No description provided for @updateAlbum.
  ///
  /// In en, this message translates to:
  /// **'Update Album'**
  String get updateAlbum;

  /// No description provided for @albumDetails.
  ///
  /// In en, this message translates to:
  /// **'Album Details'**
  String get albumDetails;

  /// No description provided for @audioUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Audio Unavailable'**
  String get audioUnavailable;

  /// No description provided for @audioFileAttached.
  ///
  /// In en, this message translates to:
  /// **'Audio File Attached'**
  String get audioFileAttached;

  /// No description provided for @videoError.
  ///
  /// In en, this message translates to:
  /// **'Video Error'**
  String get videoError;

  /// No description provided for @errorLoadingVideo.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Video'**
  String get errorLoadingVideo;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @imageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Image Not Found'**
  String get imageNotFound;

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed To Load Image'**
  String get failedToLoadImage;

  /// No description provided for @audioFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Audio File Not Found'**
  String get audioFileNotFound;

  /// No description provided for @fileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'File Not Available'**
  String get fileNotAvailable;

  /// No description provided for @failedToLoadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed To Load PDF'**
  String get failedToLoadPdf;

  /// No description provided for @pdfFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'PDF File Not Found'**
  String get pdfFileNotFound;

  /// No description provided for @deleteAlbumConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are You Sure You Want To Delete This Album?'**
  String get deleteAlbumConfirmation;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @freePostsNoCart.
  ///
  /// In en, this message translates to:
  /// **'Free Posts Cannot Be Added To Cart'**
  String get freePostsNoCart;

  /// No description provided for @ownPostsNoCart.
  ///
  /// In en, this message translates to:
  /// **'You Cannot Add Your Own Posts To Cart'**
  String get ownPostsNoCart;

  /// No description provided for @alreadyInCart.
  ///
  /// In en, this message translates to:
  /// **'Item Is Already In Your Cart'**
  String get alreadyInCart;

  /// No description provided for @linkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link Copied'**
  String get linkCopied;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report Submitted'**
  String get reportSubmitted;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Values Are Required'**
  String get fillRequiredFields;

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment Deleted'**
  String get commentDeleted;

  /// No description provided for @commentNotEmpty.
  ///
  /// In en, this message translates to:
  /// **'Comment Cannot Be Empty'**
  String get commentNotEmpty;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating Submitted'**
  String get ratingSubmitted;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bookmark Removed'**
  String get bookmarkRemoved;

  /// No description provided for @postBookmarked.
  ///
  /// In en, this message translates to:
  /// **'Post Bookmarked'**
  String get postBookmarked;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category Is Required'**
  String get categoryRequired;

  /// No description provided for @contentRequired.
  ///
  /// In en, this message translates to:
  /// **'Content Is Required'**
  String get contentRequired;

  /// No description provided for @selectUserToLogin.
  ///
  /// In en, this message translates to:
  /// **'Select User to Login'**
  String get selectUserToLogin;

  /// No description provided for @simulateLoginDesc.
  ///
  /// In en, this message translates to:
  /// **'Simulate Login As Another User'**
  String get simulateLoginDesc;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseYourLanguage;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @createPostBtn.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPostBtn;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @noContentAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Content Available'**
  String get noContentAvailable;

  /// No description provided for @writeSomething.
  ///
  /// In en, this message translates to:
  /// **'Write Something...'**
  String get writeSomething;

  /// No description provided for @creatingPost.
  ///
  /// In en, this message translates to:
  /// **'Creating Post...'**
  String get creatingPost;

  /// No description provided for @postCreated.
  ///
  /// In en, this message translates to:
  /// **'Post Created'**
  String get postCreated;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging Out...'**
  String get loggingOut;

  /// No description provided for @postNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'Post No Longer Available'**
  String get postNoLongerAvailable;

  /// No description provided for @addTracks.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks'**
  String get addTracks;

  /// No description provided for @doneAdding.
  ///
  /// In en, this message translates to:
  /// **'Done Adding'**
  String get doneAdding;

  /// No description provided for @noTracksSelected.
  ///
  /// In en, this message translates to:
  /// **'No Tracks Selected'**
  String get noTracksSelected;

  /// No description provided for @addMoreTracks.
  ///
  /// In en, this message translates to:
  /// **'Add More Tracks'**
  String get addMoreTracks;

  /// No description provided for @startStreamingBtn.
  ///
  /// In en, this message translates to:
  /// **'Start Streaming'**
  String get startStreamingBtn;

  /// No description provided for @goLiveBtn.
  ///
  /// In en, this message translates to:
  /// **'Go Live'**
  String get goLiveBtn;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @beTheFirstToSayHello.
  ///
  /// In en, this message translates to:
  /// **'Be The First To Say Hello!'**
  String get beTheFirstToSayHello;

  /// No description provided for @people.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get people;

  /// No description provided for @newPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get newPost;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit Rating'**
  String get submitRating;

  /// No description provided for @couldNotLoadPdf.
  ///
  /// In en, this message translates to:
  /// **'Could Not Load PDF'**
  String get couldNotLoadPdf;

  /// No description provided for @pdfNotFound.
  ///
  /// In en, this message translates to:
  /// **'PDF Not Found'**
  String get pdfNotFound;

  /// No description provided for @couldNotLoadPreview.
  ///
  /// In en, this message translates to:
  /// **'Could Not Load Preview'**
  String get couldNotLoadPreview;

  /// No description provided for @openFullPdf.
  ///
  /// In en, this message translates to:
  /// **'Open Full PDF'**
  String get openFullPdf;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image Not Available'**
  String get imageNotAvailable;

  /// No description provided for @postUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Post Unavailable'**
  String get postUnavailable;

  /// No description provided for @postCouldNotBeFound.
  ///
  /// In en, this message translates to:
  /// **'Post Could Not Be Found'**
  String get postCouldNotBeFound;

  /// No description provided for @invalidImagePath.
  ///
  /// In en, this message translates to:
  /// **'Invalid Image Path'**
  String get invalidImagePath;

  /// No description provided for @addTracksBtn.
  ///
  /// In en, this message translates to:
  /// **'Add Tracks'**
  String get addTracksBtn;

  /// No description provided for @selectedTracks.
  ///
  /// In en, this message translates to:
  /// **'Selected Tracks'**
  String get selectedTracks;

  /// No description provided for @noSongsOrVideosFound.
  ///
  /// In en, this message translates to:
  /// **'No Songs Or Videos Found'**
  String get noSongsOrVideosFound;

  /// No description provided for @noCommentsYetBeFirst.
  ///
  /// In en, this message translates to:
  /// **'No Comments Yet. Be The First To Comment!'**
  String get noCommentsYetBeFirst;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No Comments Yet.'**
  String get noCommentsYet;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying To'**
  String get replyingTo;

  /// No description provided for @legalFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get legalFullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Full Name'**
  String get enterYourFullName;

  /// No description provided for @enterYourUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter Your Username'**
  String get enterYourUsername;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell Us About Yourself'**
  String get tellUsAboutYourself;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @host.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// No description provided for @untitledStream.
  ///
  /// In en, this message translates to:
  /// **'Untitled Stream'**
  String get untitledStream;

  /// No description provided for @shareYourThoughts.
  ///
  /// In en, this message translates to:
  /// **'Share Your Thoughts...'**
  String get shareYourThoughts;

  /// No description provided for @clickToRate.
  ///
  /// In en, this message translates to:
  /// **'Click to Rate'**
  String get clickToRate;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @stream.
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get stream;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown Error'**
  String get unknownError;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

  /// No description provided for @reportPostFormTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPostFormTitle;

  /// No description provided for @categoryRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Category Is Required'**
  String get categoryRequiredHint;

  /// No description provided for @contentRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Content Description Is Required'**
  String get contentRequiredHint;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @categorySpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get categorySpam;

  /// No description provided for @categoryInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate Content'**
  String get categoryInappropriate;

  /// No description provided for @categoryHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get categoryHarassment;

  /// No description provided for @categoryFalseInfo.
  ///
  /// In en, this message translates to:
  /// **'False Information'**
  String get categoryFalseInfo;

  /// No description provided for @categoryCopyright.
  ///
  /// In en, this message translates to:
  /// **'Copyright Violation'**
  String get categoryCopyright;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter Description'**
  String get enterDescription;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be The First To Comment!'**
  String get beFirstToComment;

  /// No description provided for @authorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorLabel;

  /// No description provided for @addCommentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add A Comment...'**
  String get addCommentPlaceholder;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @gateway.
  ///
  /// In en, this message translates to:
  /// **'Gateway'**
  String get gateway;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @passwordSetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password Set Successfully'**
  String get passwordSetSuccessfully;

  /// No description provided for @fillAllPasswordFields.
  ///
  /// In en, this message translates to:
  /// **'Please Fill All Password Fields'**
  String get fillAllPasswordFields;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords Do Not Match'**
  String get passwordsDoNotMatch;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter Current Password'**
  String get enterCurrentPassword;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enterNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your New Password'**
  String get confirmNewPasswordHint;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save Password'**
  String get savePassword;

  /// No description provided for @paymentReceived.
  ///
  /// In en, this message translates to:
  /// **'Payment Received'**
  String get paymentReceived;

  /// No description provided for @paymentSent.
  ///
  /// In en, this message translates to:
  /// **'Payment Sent'**
  String get paymentSent;

  /// No description provided for @gatewayStripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get gatewayStripe;

  /// No description provided for @gatewayWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get gatewayWallet;

  /// No description provided for @paymentStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get paymentStatusCompleted;

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentStatusPending;

  /// No description provided for @unlockPost.
  ///
  /// In en, this message translates to:
  /// **'Unlock Post'**
  String get unlockPost;

  /// No description provided for @unlockContentDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock This Content By Subscribing To The Creator'**
  String get unlockContentDesc;

  /// No description provided for @watchPreview.
  ///
  /// In en, this message translates to:
  /// **'Watch Preview'**
  String get watchPreview;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPost;

  /// No description provided for @updatePost.
  ///
  /// In en, this message translates to:
  /// **'Update Post'**
  String get updatePost;

  /// No description provided for @shareContentEdit.
  ///
  /// In en, this message translates to:
  /// **'Share Edit'**
  String get shareContentEdit;

  /// No description provided for @postUpdated.
  ///
  /// In en, this message translates to:
  /// **'Post Updated'**
  String get postUpdated;

  /// No description provided for @previewVideo.
  ///
  /// In en, this message translates to:
  /// **'Preview Video'**
  String get previewVideo;

  /// No description provided for @previewAudio.
  ///
  /// In en, this message translates to:
  /// **'Preview Audio'**
  String get previewAudio;

  /// No description provided for @uploadPreview.
  ///
  /// In en, this message translates to:
  /// **'Upload Preview'**
  String get uploadPreview;

  /// No description provided for @tipAmount.
  ///
  /// In en, this message translates to:
  /// **'Tip Amount'**
  String get tipAmount;

  /// No description provided for @tipAmountMinMax.
  ///
  /// In en, this message translates to:
  /// **'Tip Amount (min \$1, max \$5000)'**
  String get tipAmountMinMax;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select payment method'**
  String get selectPaymentMethod;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @securePayment.
  ///
  /// In en, this message translates to:
  /// **'Secure payment'**
  String get securePayment;

  /// No description provided for @minTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Min tip amount is \$1'**
  String get minTipAmount;

  /// No description provided for @maxTipAmount.
  ///
  /// In en, this message translates to:
  /// **'Max tip amount is \$5000'**
  String get maxTipAmount;

  /// No description provided for @negativeAmountError.
  ///
  /// In en, this message translates to:
  /// **'You cannot enter a negative amount'**
  String get negativeAmountError;

  /// No description provided for @maxAmountError.
  ///
  /// In en, this message translates to:
  /// **'You cannot enter more than \$5000'**
  String get maxAmountError;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'Tip'**
  String get tip;

  /// No description provided for @totalEarnings.
  ///
  /// In en, this message translates to:
  /// **'Total Earnings'**
  String get totalEarnings;

  /// No description provided for @activeSubscribers.
  ///
  /// In en, this message translates to:
  /// **'Active Subscribers'**
  String get activeSubscribers;

  /// No description provided for @yourSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Your Subscriptions'**
  String get yourSubscriptions;

  /// No description provided for @totalSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Total Subscriptions'**
  String get totalSubscriptions;

  /// No description provided for @subscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers'**
  String get subscribers;

  /// No description provided for @subscriptionType.
  ///
  /// In en, this message translates to:
  /// **'Subscription Type'**
  String get subscriptionType;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @nextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get nextBilling;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @noSubscribersFound.
  ///
  /// In en, this message translates to:
  /// **'No Subscribers Found.'**
  String get noSubscribersFound;

  /// No description provided for @subscriberListDesc.
  ///
  /// In en, this message translates to:
  /// **'Your Subscriber List Will Appear Here Once Someone Subscribes To You.'**
  String get subscriberListDesc;

  /// No description provided for @yourSubscribersList.
  ///
  /// In en, this message translates to:
  /// **'Your Subscribers'**
  String get yourSubscribersList;

  /// No description provided for @rateMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Rate Must Be Between 5 And 100'**
  String get rateMustBeBetween;

  /// No description provided for @rateUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rate Updated!'**
  String get rateUpdated;

  /// No description provided for @updateRate.
  ///
  /// In en, this message translates to:
  /// **'Update Rate'**
  String get updateRate;

  /// No description provided for @rateSetToFree.
  ///
  /// In en, this message translates to:
  /// **'Rate Set To Free!'**
  String get rateSetToFree;

  /// No description provided for @makeFree.
  ///
  /// In en, this message translates to:
  /// **'Make Free'**
  String get makeFree;

  /// No description provided for @timeMustBeBetween.
  ///
  /// In en, this message translates to:
  /// **'Time Must Be Between 0 And 60 Minutes'**
  String get timeMustBeBetween;

  /// No description provided for @timeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Time Updated!'**
  String get timeUpdated;

  /// No description provided for @updateTime.
  ///
  /// In en, this message translates to:
  /// **'Update Time'**
  String get updateTime;

  /// No description provided for @disconnectionDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disconnection Disabled!'**
  String get disconnectionDisabled;

  /// No description provided for @disableDisconnection.
  ///
  /// In en, this message translates to:
  /// **'Disable Disconnection'**
  String get disableDisconnection;

  /// No description provided for @notificationSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings Saved'**
  String get notificationSettingsSaved;

  /// No description provided for @deletePostQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePostQuestion;

  /// No description provided for @deletePostConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this post?'**
  String get deletePostConfirmation;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @sentToOzVault.
  ///
  /// In en, this message translates to:
  /// **'Sent to Oz Vault'**
  String get sentToOzVault;

  /// No description provided for @sendToOzVault.
  ///
  /// In en, this message translates to:
  /// **'Send To OzVault'**
  String get sendToOzVault;

  /// No description provided for @unableToUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unable To Unfollow User'**
  String get unableToUnfollow;

  /// No description provided for @noOptionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Options Available'**
  String get noOptionsAvailable;

  /// No description provided for @cartNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Cart Is Not Available'**
  String get cartNotAvailable;

  /// No description provided for @artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **' *'**
  String get requiredField;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @findAnswers.
  ///
  /// In en, this message translates to:
  /// **'Find answers here'**
  String get findAnswers;

  /// No description provided for @faqQ1.
  ///
  /// In en, this message translates to:
  /// **'How do I create a new post?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In en, this message translates to:
  /// **'To create a post, tap the \'+\' icon in the center of the bottom navigation bar. Choose the type of content you want to share, upload your files, and tap \'Publish\'.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In en, this message translates to:
  /// **'How can I block a user?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In en, this message translates to:
  /// **'Go to the user\'s profile, tap on the options menu (dots), and select \'Block User\'. You will no longer see their content.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In en, this message translates to:
  /// **'Is the app free to use?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In en, this message translates to:
  /// **'The app is free to download and explore. Some creators may offer premium content that requires a subscription or a one-time payment.'**
  String get faqA3;

  /// No description provided for @uploadFileError.
  ///
  /// In en, this message translates to:
  /// **'Please Upload The {fileType} File'**
  String uploadFileError(Object fileType);

  /// No description provided for @errorCreatingPost.
  ///
  /// In en, this message translates to:
  /// **'Error Creating Post: {error}'**
  String errorCreatingPost(Object error);

  /// No description provided for @replyToAuthor.
  ///
  /// In en, this message translates to:
  /// **'Reply To @{author}'**
  String replyToAuthor(Object author);

  /// No description provided for @streamLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Stream: {error}'**
  String streamLoadError(Object error);

  /// No description provided for @refreshedStreamsFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count} Streams'**
  String refreshedStreamsFound(Object count);

  /// No description provided for @payToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Pay {price} To Unlock'**
  String payToUnlock(Object price);

  /// No description provided for @subscribeToUser.
  ///
  /// In en, this message translates to:
  /// **'Subscribe To {name}'**
  String subscribeToUser(Object name);

  /// No description provided for @successfullyDeposited.
  ///
  /// In en, this message translates to:
  /// **'Successfully Deposited {amount}'**
  String successfullyDeposited(Object amount);

  /// No description provided for @walletDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit: {amount}'**
  String walletDeposit(Object amount);

  /// No description provided for @walletWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal: {amount}'**
  String walletWithdrawal(Object amount);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} Minutes Ago'**
  String minutesAgo(Object count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} Hours Ago'**
  String hoursAgo(Object count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} Days Ago'**
  String daysAgo(Object count);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} Weeks Ago'**
  String weeksAgo(Object count);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} Months Ago'**
  String monthsAgo(Object count);

  /// No description provided for @removeFromCartConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {item} From Cart?'**
  String removeFromCartConfirm(Object item);

  /// No description provided for @rates.
  ///
  /// In en, this message translates to:
  /// **'Rates'**
  String get rates;

  /// No description provided for @currentRate.
  ///
  /// In en, this message translates to:
  /// **'Current Rate'**
  String get currentRate;

  /// No description provided for @profileSubscriptionPrice.
  ///
  /// In en, this message translates to:
  /// **'Profile Subscription price'**
  String get profileSubscriptionPrice;

  /// No description provided for @setNewRate.
  ///
  /// In en, this message translates to:
  /// **'Set New Rate'**
  String get setNewRate;

  /// No description provided for @enterNewRateHint.
  ///
  /// In en, this message translates to:
  /// **'Enter New Rate (Min: 5, Max: 100)'**
  String get enterNewRateHint;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current Time'**
  String get currentTime;

  /// No description provided for @callCenterTimingDesc.
  ///
  /// In en, this message translates to:
  /// **'Call Center Timing (Call Will Be Disconnected After This Time, 0 Will Be Infinite)'**
  String get callCenterTimingDesc;

  /// No description provided for @setNewTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'Set New Time (Minutes)'**
  String get setNewTimeMinutes;

  /// No description provided for @enterMinutesHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Minutes (0-60)'**
  String get enterMinutesHint;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not Set'**
  String get notSet;

  /// No description provided for @blockUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockUserConfirm(Object name);

  /// No description provided for @subscribedTo.
  ///
  /// In en, this message translates to:
  /// **'Subscribed to {name}'**
  String subscribedTo(Object name);

  /// No description provided for @subscribedToYou.
  ///
  /// In en, this message translates to:
  /// **'{name} subscribed to you'**
  String subscribedToYou(Object name);

  /// No description provided for @getCertificateCount.
  ///
  /// In en, this message translates to:
  /// **'Get Certificate ({count})'**
  String getCertificateCount(Object count);

  /// No description provided for @publishSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Publish Selected ({count})'**
  String publishSelectedCount(Object count);

  /// No description provided for @selectedContentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedContentCount(Object count);

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date}'**
  String createdOn(Object date);

  /// No description provided for @publishedOn.
  ///
  /// In en, this message translates to:
  /// **'Published on {date}'**
  String publishedOn(Object date);

  /// No description provided for @filesSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} files selected'**
  String filesSelectedCount(Object count);

  /// No description provided for @peopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String peopleCount(Object count);

  /// No description provided for @likeNotification.
  ///
  /// In en, this message translates to:
  /// **'{count} new likes on {postTitle}'**
  String likeNotification(Object count, Object postTitle);

  /// No description provided for @commentNotification.
  ///
  /// In en, this message translates to:
  /// **'{author} commented: {comment}'**
  String commentNotification(Object author, Object comment);

  /// No description provided for @replyNotification.
  ///
  /// In en, this message translates to:
  /// **'{author} replied: {comment}'**
  String replyNotification(Object author, Object comment);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String tracksCount(Object count);

  /// No description provided for @albumCreated.
  ///
  /// In en, this message translates to:
  /// **'Album created: {title}'**
  String albumCreated(Object title);

  /// No description provided for @errorLoadingPdf.
  ///
  /// In en, this message translates to:
  /// **'Error loading PDF: {error}'**
  String errorLoadingPdf(Object error);

  /// No description provided for @loginAsUser.
  ///
  /// In en, this message translates to:
  /// **'Login as {name}'**
  String loginAsUser(Object name);

  /// No description provided for @errorSavingPost.
  ///
  /// In en, this message translates to:
  /// **'Error saving post: {error}'**
  String errorSavingPost(Object error);

  /// No description provided for @errorAddingToCart.
  ///
  /// In en, this message translates to:
  /// **'Error adding to cart: {error}'**
  String errorAddingToCart(Object error);

  /// No description provided for @liveStreamsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Live Streams'**
  String liveStreamsCount(Object count);

  /// No description provided for @refreshedStreams.
  ///
  /// In en, this message translates to:
  /// **'Refreshed {count} streams'**
  String refreshedStreams(Object count);

  /// No description provided for @errorPostingComment.
  ///
  /// In en, this message translates to:
  /// **'Error posting comment: {error}'**
  String errorPostingComment(Object error);

  /// No description provided for @itemOutOfStock.
  ///
  /// In en, this message translates to:
  /// **'{item} is out of stock'**
  String itemOutOfStock(Object item);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(Object count);

  /// No description provided for @unlockFor.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String unlockFor(Object price);

  /// No description provided for @sendTip.
  ///
  /// In en, this message translates to:
  /// **'Send {amount}'**
  String sendTip(Object amount);

  /// No description provided for @tipSent.
  ///
  /// In en, this message translates to:
  /// **'Tip of {amount} sent!'**
  String tipSent(Object amount);

  /// No description provided for @artistRate.
  ///
  /// In en, this message translates to:
  /// **'Artist Rate: {rate}/hr'**
  String artistRate(Object rate);

  /// No description provided for @limitReachedAudio.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached: {current}/{limit} Audio Tracks'**
  String limitReachedAudio(Object current, Object limit);

  /// No description provided for @limitReachedVideo.
  ///
  /// In en, this message translates to:
  /// **'Limit Reached: {current}/{limit} Video Files'**
  String limitReachedVideo(Object current, Object limit);

  /// No description provided for @unfollowed.
  ///
  /// In en, this message translates to:
  /// **'Unfollowed {name}'**
  String unfollowed(Object name);

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked {name}'**
  String blocked(Object name);

  /// No description provided for @failedToLogin.
  ///
  /// In en, this message translates to:
  /// **'Failed to login: {error}'**
  String failedToLogin(Object error);

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenZippers'**
  String get appTitle;

  /// No description provided for @monthShortJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthShortJan;

  /// No description provided for @monthShortFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthShortFeb;

  /// No description provided for @monthShortMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthShortMar;

  /// No description provided for @monthShortApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthShortApr;

  /// No description provided for @monthShortMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthShortMay;

  /// No description provided for @monthShortJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthShortJun;

  /// No description provided for @monthShortJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthShortJul;

  /// No description provided for @monthShortAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthShortAug;

  /// No description provided for @monthShortSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthShortSep;

  /// No description provided for @monthShortOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthShortOct;

  /// No description provided for @monthShortNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthShortNov;

  /// No description provided for @monthShortDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthShortDec;

  /// No description provided for @payForAvailableItemsPlural.
  ///
  /// In en, this message translates to:
  /// **'Pay for {count} available items'**
  String payForAvailableItemsPlural(Object count);

  /// No description provided for @payForAvailableItems.
  ///
  /// In en, this message translates to:
  /// **'Pay for {count} available item'**
  String payForAvailableItems(Object count);

  /// No description provided for @allowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications'**
  String get allowNotifications;

  /// No description provided for @notificationNewLike.
  ///
  /// In en, this message translates to:
  /// **'New like received'**
  String get notificationNewLike;

  /// No description provided for @notificationNewSub.
  ///
  /// In en, this message translates to:
  /// **'New subscription registered'**
  String get notificationNewSub;

  /// No description provided for @notificationTip.
  ///
  /// In en, this message translates to:
  /// **'Received a tip'**
  String get notificationTip;

  /// No description provided for @notificationMessage.
  ///
  /// In en, this message translates to:
  /// **'New message received'**
  String get notificationMessage;

  /// No description provided for @notificationComment.
  ///
  /// In en, this message translates to:
  /// **'New comment received'**
  String get notificationComment;

  /// No description provided for @notificationExpiringSub.
  ///
  /// In en, this message translates to:
  /// **'Expiring subscriptions'**
  String get notificationExpiringSub;

  /// No description provided for @notificationRenewal.
  ///
  /// In en, this message translates to:
  /// **'Upcoming renewals'**
  String get notificationRenewal;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @joined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joined(Object date);

  /// No description provided for @welcomeProfile.
  ///
  /// In en, this message translates to:
  /// **'Welcome to my profile!'**
  String get welcomeProfile;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @monthFullJan.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get monthFullJan;

  /// No description provided for @monthFullFeb.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get monthFullFeb;

  /// No description provided for @monthFullMar.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get monthFullMar;

  /// No description provided for @monthFullApr.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get monthFullApr;

  /// No description provided for @monthFullMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthFullMay;

  /// No description provided for @monthFullJun.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get monthFullJun;

  /// No description provided for @monthFullJul.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get monthFullJul;

  /// No description provided for @monthFullAug.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get monthFullAug;

  /// No description provided for @monthFullSep.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get monthFullSep;

  /// No description provided for @monthFullOct.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get monthFullOct;

  /// No description provided for @monthFullNov.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get monthFullNov;

  /// No description provided for @monthFullDec.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get monthFullDec;

  /// No description provided for @streamArtist.
  ///
  /// In en, this message translates to:
  /// **'Stream Artist'**
  String get streamArtist;

  /// No description provided for @followArtistToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Follow this artist to unlock their content.'**
  String get followArtistToUnlock;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @followToSeeContent.
  ///
  /// In en, this message translates to:
  /// **'Follow to see content'**
  String get followToSeeContent;

  /// No description provided for @contentDetails.
  ///
  /// In en, this message translates to:
  /// **'Content Details'**
  String get contentDetails;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @dimension.
  ///
  /// In en, this message translates to:
  /// **'Dimension'**
  String get dimension;

  /// No description provided for @uploadedOn.
  ///
  /// In en, this message translates to:
  /// **'Uploaded on'**
  String get uploadedOn;

  /// No description provided for @faqQ4.
  ///
  /// In en, this message translates to:
  /// **'How can I update my account details?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In en, this message translates to:
  /// **'To update your account details, go to your profile page and tap on \'Edit Profile\'. There you can change your display name, bio, and profile picture.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In en, this message translates to:
  /// **'How do I purchase music or videos?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In en, this message translates to:
  /// **'Login your account & Go to the feed page or an artist\'s profile. Tap on the content you want to buy. You can use your wallet balance or a credit card to complete the purchase.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In en, this message translates to:
  /// **'Is there a limit to the number of items I can buy?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In en, this message translates to:
  /// **'No, there is no limit to the number of items you can buy.'**
  String get faqA6;

  /// No description provided for @rateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Rate & Time'**
  String get rateAndTime;

  /// No description provided for @postLiked.
  ///
  /// In en, this message translates to:
  /// **'Post Liked'**
  String get postLiked;

  /// No description provided for @postUnliked.
  ///
  /// In en, this message translates to:
  /// **'Post Unliked'**
  String get postUnliked;

  /// No description provided for @commentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted!'**
  String get commentPosted;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post Deleted'**
  String get postDeleted;

  /// No description provided for @postUpdatedSnack.
  ///
  /// In en, this message translates to:
  /// **'Post Updated'**
  String get postUpdatedSnack;

  /// No description provided for @cartUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cart Updated'**
  String get cartUpdated;

  /// No description provided for @ratingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// No description provided for @ratingFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get ratingFair;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// No description provided for @ratingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get ratingVeryGood;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get ratingExcellent;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating:'**
  String get averageRating;

  /// No description provided for @totalRatings.
  ///
  /// In en, this message translates to:
  /// **'Total ratings:'**
  String get totalRatings;

  /// No description provided for @editPostTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Post'**
  String get editPostTitle;

  /// No description provided for @readyToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Ready to Update'**
  String get readyToUpdate;

  /// No description provided for @reviewAndUpdate.
  ///
  /// In en, this message translates to:
  /// **'Review your content and Update'**
  String get reviewAndUpdate;

  /// No description provided for @updatePostBtn.
  ///
  /// In en, this message translates to:
  /// **'Update Post'**
  String get updatePostBtn;

  /// No description provided for @shortTeaserMax10s.
  ///
  /// In en, this message translates to:
  /// **'Short teaser (Max 10s)'**
  String get shortTeaserMax10s;

  /// No description provided for @cropImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop Image'**
  String get cropImageTitle;

  /// No description provided for @tipReceived.
  ///
  /// In en, this message translates to:
  /// **'Tip Received'**
  String get tipReceived;

  /// No description provided for @newSubscriber.
  ///
  /// In en, this message translates to:
  /// **'New Subscriber'**
  String get newSubscriber;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @subscribed.
  ///
  /// In en, this message translates to:
  /// **'Subscribed'**
  String get subscribed;

  /// No description provided for @subscribePrice.
  ///
  /// In en, this message translates to:
  /// **'Subscribe {price}/month'**
  String subscribePrice(Object price);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @shareProfileText.
  ///
  /// In en, this message translates to:
  /// **'Check out {name}\'s profile on OpenZippers: {url}'**
  String shareProfileText(Object name, Object url);

  /// No description provided for @shareProfileSubject.
  ///
  /// In en, this message translates to:
  /// **'Check out this profile!'**
  String get shareProfileSubject;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @lockedContent.
  ///
  /// In en, this message translates to:
  /// **'Locked Content'**
  String get lockedContent;

  /// No description provided for @tapToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'Tap to open file'**
  String get tapToOpenFile;

  /// No description provided for @subscribeToAccess.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to access'**
  String get subscribeToAccess;

  /// No description provided for @writingText.
  ///
  /// In en, this message translates to:
  /// **'Writing Text'**
  String get writingText;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @becomeCreator.
  ///
  /// In en, this message translates to:
  /// **'Become Creator'**
  String get becomeCreator;

  /// No description provided for @becomeCreatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our community and start earning'**
  String get becomeCreatorSubtitle;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @getVerifiedEarnNow.
  ///
  /// In en, this message translates to:
  /// **'Get verified and start earning now.'**
  String get getVerifiedEarnNow;

  /// No description provided for @completeVerificationSteps.
  ///
  /// In en, this message translates to:
  /// **'Complete the verification steps below to verify your profile and unlock all platform features.'**
  String get completeVerificationSteps;

  /// No description provided for @confirmEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address'**
  String get confirmEmailAddress;

  /// No description provided for @emailVerifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your email address has been verified successfully.'**
  String get emailVerifiedSuccessfully;

  /// No description provided for @uploadVerificationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload verification documents'**
  String get uploadVerificationDocuments;

  /// No description provided for @uploadGovIdInstructions.
  ///
  /// In en, this message translates to:
  /// **'Upload your Government ID (front & back) and a passport photo to complete verification.'**
  String get uploadGovIdInstructions;

  /// No description provided for @governmentIdFront.
  ///
  /// In en, this message translates to:
  /// **'Government ID Front'**
  String get governmentIdFront;

  /// No description provided for @governmentIdBack.
  ///
  /// In en, this message translates to:
  /// **'Government ID Back'**
  String get governmentIdBack;

  /// No description provided for @passportSizePhoto.
  ///
  /// In en, this message translates to:
  /// **'Passport Size Photo'**
  String get passportSizePhoto;

  /// No description provided for @imageFormatSize.
  ///
  /// In en, this message translates to:
  /// **'JPG, GIF or PNG. Max 10MB'**
  String get imageFormatSize;

  /// No description provided for @uploadAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload All Documents'**
  String get uploadAllDocuments;

  /// No description provided for @errorPickingImage.
  ///
  /// In en, this message translates to:
  /// **'Error picking image: {error}'**
  String errorPickingImage(Object error);

  /// No description provided for @pleaseSelectAllDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please select all required documents'**
  String get pleaseSelectAllDocuments;

  /// No description provided for @documentsUploadedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Documents uploaded successfully! Your verification is under review.'**
  String get documentsUploadedSuccess;

  /// No description provided for @errorUploadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error uploading documents'**
  String get errorUploadingDocuments;

  /// No description provided for @subscribeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Unlock'**
  String get subscribeToUnlock;

  /// No description provided for @changeCover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get changeCover;

  /// No description provided for @noResultsFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No results found for'**
  String get noResultsFoundFor;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPostsYet;

  /// No description provided for @suggestedForYou.
  ///
  /// In en, this message translates to:
  /// **'Suggested For You'**
  String get suggestedForYou;

  /// No description provided for @followerLabel.
  ///
  /// In en, this message translates to:
  /// **'followers'**
  String get followerLabel;

  /// No description provided for @followingLabel.
  ///
  /// In en, this message translates to:
  /// **'following'**
  String get followingLabel;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get verified and start earning now.'**
  String get verificationSubtitle;

  /// No description provided for @verificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the verification steps below to verify your profile and unlock all platform features.'**
  String get verificationDesc;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email address'**
  String get confirmEmail;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your email address has been verified successfully.'**
  String get emailVerifiedSuccess;

  /// No description provided for @verifyEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address.'**
  String get verifyEmailDesc;

  /// No description provided for @verifiedBtn.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifiedBtn;

  /// No description provided for @verifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyBtn;

  /// No description provided for @becomeArtist.
  ///
  /// In en, this message translates to:
  /// **'Become an Artist'**
  String get becomeArtist;

  /// No description provided for @becomeArtistDesc.
  ///
  /// In en, this message translates to:
  /// **'To create paid content and access verification features, you need to become an artist. This action is irreversible - you will not be able to revert back to a regular user account.'**
  String get becomeArtistDesc;

  /// No description provided for @becomeArtistInstructions.
  ///
  /// In en, this message translates to:
  /// **'Take photos of your Government ID front, Government ID back, and a live photo holding your real name written on a piece of paper below, then click Convert to Artist.'**
  String get becomeArtistInstructions;

  /// No description provided for @govIdFront.
  ///
  /// In en, this message translates to:
  /// **'Government ID Front'**
  String get govIdFront;

  /// No description provided for @govIdFrontDesc.
  ///
  /// In en, this message translates to:
  /// **'Take photo of Government ID Front'**
  String get govIdFrontDesc;

  /// No description provided for @govIdBack.
  ///
  /// In en, this message translates to:
  /// **'Government ID Back'**
  String get govIdBack;

  /// No description provided for @govIdBackDesc.
  ///
  /// In en, this message translates to:
  /// **'Take photo of Government ID Back'**
  String get govIdBackDesc;

  /// No description provided for @livePhoto.
  ///
  /// In en, this message translates to:
  /// **'Live Photo with Your Name'**
  String get livePhoto;

  /// No description provided for @livePhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a live photo holding your real name written on a piece of paper'**
  String get livePhotoDesc;

  /// No description provided for @convertToArtist.
  ///
  /// In en, this message translates to:
  /// **'Convert to Artist'**
  String get convertToArtist;

  /// No description provided for @takeAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'Take all three photos above to continue.'**
  String get takeAllPhotos;

  /// No description provided for @verificationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Verification documents submitted successfully!'**
  String get verificationSubmitted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'fi',
    'fil',
    'fr',
    'hi',
    'hu',
    'id',
    'it',
    'ja',
    'ko',
    'ms',
    'nl',
    'no',
    'pl',
    'pt',
    'ro',
    'ru',
    'sv',
    'sw',
    'th',
    'tr',
    'ur',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fil':
      return AppLocalizationsFil();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
