import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../l10n/generated/app_localizations_en.dart';

///Translation helper that provides localized strings throughout the app
class AppTranslations {
  final BuildContext context;
  late final AppLocalizations _l10n;
  
  AppTranslations(this.context) {
    var localizations = AppLocalizations.of(context);
    localizations ??= AppLocalizationsEn();
    _l10n = localizations;
  }
  
  // Navigation
  String get home => _l10n.home;
  String get explore => _l10n.explore;
  String get add => _l10n.add;
  String get reels => _l10n.reels;
  String get live => _l10n.live;
  String get profile => _l10n.profile;
  String get settings => _l10n.settings;
  String get connections => _l10n.connections;
  String get search => _l10n.search;
  String get liveStreams => _l10n.liveStreams;
  String get bookmark => _l10n.bookmark;
  String get cart => _l10n.cart;
  String get gallery => _l10n.gallery;
  String get camera => _l10n.camera;
  String get helpSupport => _l10n.helpSupport;
  String get streaming => _l10n.streaming;
  
  // Actions
  String get like => _l10n.like;
  String get comment => _l10n.comment;
  String get share => _l10n.share;
  String get save => _l10n.save;
  String get delete => _l10n.delete;
  String get edit => _l10n.edit;
  String get post => _l10n.post;
  String get submit => _l10n.submit;
  String get confirm => _l10n.confirm;
  String get cancel => _l10n.cancel;
  String get back => _l10n.back;
  String get next => _l10n.next;
  String get done => _l10n.done;
  String get close => _l10n.close;
  String get changeFile => _l10n.changeFile;
  String get follow => _l10n.follow;
  String get unfollow => _l10n.unfollow;
  String get message => _l10n.message;
  String get block => _l10n.block;
  String get report => _l10n.report;
  String get send => _l10n.send;
  String get reply => _l10n.reply;
  
  // Profile
  String get followers => _l10n.followers;
  String get follower => _l10n.follower;
  String get following => _l10n.following;
  String get posts => _l10n.posts;
  String get editProfile => _l10n.editProfile;
  String get bio => _l10n.bio;
  String get about => _l10n.about;
  String get verified => _l10n.verified;
  String get changeCover => _l10n.changeCover;
  
  // Engagement
  String get likes => _l10n.likes;
  String get comments => _l10n.comments;
  String get shares => _l10n.shares;
  String get views => _l10n.views;
  String get reads => _l10n.reads;
  
  // Content types
  String get image => _l10n.image;
  String get video => _l10n.video;
  String get song => _l10n.song;
  String get literature => _l10n.literature;
  String get reel => _l10n.reel;
  String get genre => _l10n.genre;
  String get selectGenre => _l10n.selectGenre;
  
  // Forms
  String get title => _l10n.title;
  String get description => _l10n.description;
  String get content => _l10n.content;
  String get price => _l10n.price;
  String get free => _l10n.free;
  String get suggestions => _l10n.suggestions;
  String get paid => _l10n.paid;
  String get uploadImage => _l10n.uploadImage;
  String get uploadVideo => _l10n.uploadVideo;
  String get chooseFile => _l10n.chooseFile;
  String get enterText => _l10n.enterText;
  String get searchPlaceholder => _l10n.searchPlaceholder;
  
  // Cart & Commerce
  String get addToCart => _l10n.addToCart;
  String get removeFromCart => _l10n.removeFromCart;
  String get checkout => _l10n.checkout;
  String get total => _l10n.total;
  String get subtotal => _l10n.subtotal;
  
  // Status messages
  String get error => _l10n.error;
  String get success => _l10n.success;
  String get warning => _l10n.warning;
  String get loading => _l10n.loading;
  String get pleaseWait => _l10n.pleaseWait;
  String get enterTitleError => _l10n.enterTitleError;
  String get selectLanguageError => _l10n.selectLanguageError;
  String get contentProcessingError => _l10n.contentProcessingError;
  String get uploadPdfError => _l10n.uploadPdfError;
  String get pdfFileNotExistError => _l10n.pdfFileNotExistError;
  String get notPdfError => _l10n.notPdfError;
  String get pdfValidationError => _l10n.pdfValidationError;
  String get writeContentError => _l10n.writeContentError;
  String uploadFileError(Object fileType) => _l10n.uploadFileError(fileType);
  String get fileNotExistError => _l10n.fileNotExistError;
  String get fileValidationError => _l10n.fileValidationError;
  String get uploadCoverImageError => _l10n.uploadCoverImageError;
  String errorCreatingPost(Object error) => _l10n.errorCreatingPost(error);
  String get langEnglish => _l10n.langEnglish;
  String get langSpanish => _l10n.langSpanish;
  String get langFrench => _l10n.langFrench;
  String get langGerman => _l10n.langGerman;
  String get audio => _l10n.audio;
  String get imageLabel => _l10n.imageLabel;
  String get videoLabel => _l10n.videoLabel;
  String get audioLabel => _l10n.audioLabel;
  String replyToAuthor(Object author) => _l10n.replyToAuthor(author);
  String get noResults => _l10n.noResults;
  String get somethingWrong => _l10n.somethingWrong;
  String get noResultsFoundFor => _l10n.noResultsFoundFor;
  String get noPostsYet => _l10n.noPostsYet;
  String get suggestedForYou => _l10n.suggestedForYou;
  
  // Notifications
  String get notifications => _l10n.notifications;
  String get newFollower => _l10n.newFollower;
  String get likedPost => _l10n.likedPost;
  String get commentedPost => _l10n.commentedPost;
  
  // Post creation
  String get createPost => _l10n.createPost;
  String get writeCaption => _l10n.writeCaption;
  String get addLocation => _l10n.addLocation;
  String get tagPeople => _l10n.tagPeople;
  
  // UI elements
  String get viewMore => _l10n.viewMore;
  String get viewLess => _l10n.viewLess;
  String get seeAll => _l10n.seeAll;
  String get showMore => _l10n.showMore;
  String get showLess => _l10n.showLess;
  String get suggested => _l10n.suggested;
  String get forYou => _l10n.forYou;
  String get trending => _l10n.trending;
  String get popular => _l10n.popular;
  String get copyLink => _l10n.copyLink;
  String get sharePost => _l10n.sharePost;
  
  // Settings
  String get rateAndTime => _l10n.rateAndTime;
  String get language => _l10n.language;
  String get selectLanguage => _l10n.selectLanguage;
  String get darkMode => _l10n.darkMode;
  String get lightMode => _l10n.lightMode;
  String get logout => _l10n.logout;
  String get confirmLogout => _l10n.confirmLogout;
  String get ok => _l10n.ok;
  String get theme => _l10n.theme;
  String get enableNotifications => _l10n.enableNotifications;
  String get postLikes => _l10n.postLikes;
  String get postComments => _l10n.postComments;
  String get manageAccount => _l10n.manageAccount;
  String get manageAccountSubtitle => _l10n.manageAccountSubtitle;
  String get currentBalance => _l10n.currentBalance;
  String get deposit => _l10n.deposit;
  String get enterAmount => _l10n.enterAmount;
  String get quickAmounts => _l10n.quickAmounts;
  String get clear => _l10n.clear;
  String get walletTransactionHistory => _l10n.walletTransactionHistory;
  String get paymentHistory => _l10n.paymentHistory;
  String get subscriptionHistory => _l10n.subscriptionHistory;
  String get account => _l10n.account;
  String get signOut => _l10n.signOut;
  String get contactSupport => _l10n.contactSupport;
  String get getInTouch => _l10n.getInTouch;
  String get gettingStarted => _l10n.gettingStarted;
  String get learnBasics => _l10n.learnBasics;
  String get creatingAccount => _l10n.creatingAccount;
  String get creatingAccountDesc => _l10n.creatingAccountDesc;
  String get exploringPlatform => _l10n.exploringPlatform;
  String get exploringPlatformDesc => _l10n.exploringPlatformDesc;
  String get setupProfile => _l10n.setupProfile;
  String get setupProfileDesc => _l10n.setupProfileDesc;
  String get currentlyDark => _l10n.currentlyDark;
  String get currentlyLight => _l10n.currentlyLight;
  
  // Live Streaming
  String get liveNow => _l10n.liveNow;
  String get goLive => _l10n.goLive;
  String get startLiveStream => _l10n.startLiveStream;
  String get startStreaming => _l10n.startStreaming;
  String get startStream => _l10n.startStream;
  String get endStream => _l10n.endStream;
  String get youAreLive => _l10n.youAreLive;
  String get streamTitle => _l10n.streamTitle;
  String get streamTitleRequired => _l10n.streamTitleRequired;
  String get configureStreamSettings => _l10n.configureStreamSettings;
  String get joinStreamById => _l10n.joinStreamById;
  String get joinStream => _l10n.joinStream;
  String streamLoadError(String error) => _l10n.streamLoadError(error);
  String get allStreamsCleared => _l10n.allStreamsCleared;
  String get onlyArtistsCanStream => _l10n.onlyArtistsCanStream;
  String refreshedStreamsFound(int count) => _l10n.refreshedStreamsFound(count);
  String get streamLocked => _l10n.streamLocked;
  String get streamRequiresPayment => _l10n.streamRequiresPayment;
  String get oneTimePayment => _l10n.oneTimePayment;
  String get unlockStream => _l10n.unlockStream;
  String payToUnlock(String price) => _l10n.payToUnlock(price);
  String get payAndUnlock => _l10n.payAndUnlock;
  String get subscribeToArtist => _l10n.subscribeToArtist;
  String subscribeToUser(String name) => _l10n.subscribeToUser(name);
  String get subscribe => _l10n.subscribe;
  String get chatLocked => _l10n.chatLocked;
  String get unlockStreamToChat => _l10n.unlockStreamToChat;
  String get liveChat => _l10n.liveChat;
  String get noMessagesYet => _l10n.noMessagesYet;
  String get beFirstToSayHello => _l10n.beFirstToSayHello;
  String get streamAnalytics => _l10n.streamAnalytics;
  String get cameraOff => _l10n.cameraOff;
  
  // Wallet & Payments
  String get wallet => _l10n.wallet;
  String get pleaseEnterValidAmount => _l10n.pleaseEnterValidAmount;
  String get amountCleared => _l10n.amountCleared;
  String get balanceCleared => _l10n.balanceCleared;
  String get currencySymbol => _l10n.currencySymbol;
  String successfullyDeposited(String amount) => _l10n.successfullyDeposited(amount);
  String walletDeposit(String amount) => _l10n.walletDeposit(amount);
  String walletWithdrawal(String amount) => _l10n.walletWithdrawal(amount);
  String get withdraw => _l10n.withdraw;
  String get transactionHistory => _l10n.transactionHistory;
  String get payments => _l10n.payments;
  String get subscriptions => _l10n.subscriptions;
  String get history => _l10n.history;
  String get manageWallet => _l10n.manageWallet;
  String get viewPaymentHistory => _l10n.viewPaymentHistory;
  
  // Empty States
  String get emptyCart => _l10n.emptyCart;
  String get noNotifications => _l10n.noNotifications;
  String get noPosts => _l10n.noPosts;
  String get noPostsAvailable => _l10n.noPostsAvailable;
  String get followCreatorsToSeePosts => _l10n.followCreatorsToSeePosts;
  String get viewMyPosts => _l10n.viewMyPosts;
  String get exploreCreators => _l10n.exploreCreators;
  String get myPosts => _l10n.myPosts;
  String get allPosts => _l10n.allPosts;
  String get bookmarks => _l10n.bookmarks;
  String get browsePosts => _l10n.browsePosts;
  String get createFirstPost => _l10n.createFirstPost;
  String get albums => _l10n.albums;
  String get myAlbums => _l10n.myAlbums;
  String get createAlbum => _l10n.createAlbum;
  String get manageAlbumsSubtitle => _l10n.manageAlbumsSubtitle;
  String get noConnections => _l10n.noConnections;
  
  // Form Fields
  String get username => _l10n.username;
  String get password => _l10n.password;
  String get email => _l10n.email;
  String get phoneNumber => _l10n.phoneNumber;
  String get name => _l10n.name;
  String get website => _l10n.website;
  String get location => _l10n.location;
  String get gender => _l10n.gender;
  String get dateOfBirth => _l10n.dateOfBirth;
  String get saveChanges => _l10n.saveChanges;
  String get discardChanges => _l10n.discardChanges;
  
  // Support
  String get subject => _l10n.subject;
  String get subjectRequired => _l10n.subjectRequired;
  String get messageRequired => _l10n.messageRequired;
  String get supportRequestSubmitted => _l10n.supportRequestSubmitted;
  String get fillAllRequiredFields => _l10n.fillAllRequiredFields;
  String get enterSubject => _l10n.enterSubject;
  String get category => _l10n.category;
  String get typeMessage => _l10n.typeMessage;
  String get sendMessage => _l10n.sendMessage;
  String get accountIssues => _l10n.accountIssues;
  String get streamingProblems => _l10n.streamingProblems;
  String get billingQuestions => _l10n.billingQuestions;
  String get technicalSupport => _l10n.technicalSupport;
  
  // Time formatting
  String get justNow => _l10n.justNow;
  String minutesAgo(int count) => _l10n.minutesAgo(count);
  String hoursAgo(int count) => _l10n.hoursAgo(count);
  String daysAgo(int count) => _l10n.daysAgo(count);
  String weeksAgo(int count) => _l10n.weeksAgo(count);
  String monthsAgo(int count) => _l10n.monthsAgo(count);
  
  // Cart
  String get myCart => _l10n.myCart;
  String get orderPlaced => _l10n.orderPlaced;
  String get orderPlacedSuccess => _l10n.orderPlacedSuccess;
  String get noItemsInCart => _l10n.noItemsInCart;
  String get addItemsToCart => _l10n.addItemsToCart;
  String get removeItem => _l10n.removeItem;
  String removeFromCartConfirm(String item) => _l10n.removeFromCartConfirm(item);
  String get remove => _l10n.remove;
  String get proceedToPayment => _l10n.proceedToPayment;
  String payForAvailableItems(int count) => count == 1 ? _l10n.payForAvailableItems(count) : _l10n.payForAvailableItemsPlural(count);
  String get noLongerAvailable => _l10n.noLongerAvailable;
  String get itemNoLongerAvailable => _l10n.itemNoLongerAvailable;
  String get allItemsNoLongerAvailable => _l10n.allItemsNoLongerAvailable;
  String get qty => _l10n.qty;
  
  // Connections
  String get manageConnections => _l10n.manageConnections;
  String get searchConnections => _l10n.searchConnections;
  String get followBack => _l10n.followBack;
  String get unblock => _l10n.unblock;
  String get action => _l10n.action;
  String get blockUser => _l10n.blockUser;
  String blockUserConfirm(String name) => _l10n.blockUserConfirm(name);
  String get noFollowersYet => _l10n.noFollowersYet;
  String get shareProfileToGetDiscovered => _l10n.shareProfileToGetDiscovered;
  String get notFollowingAnyone => _l10n.notFollowingAnyone;
  String get exploreToFindCreators => _l10n.exploreToFindCreators;
  String get clearList => _l10n.clearList;
  String get noBlockedUsers => _l10n.noBlockedUsers;
  String get nothingHere => _l10n.nothingHere;
  
  // Notifications
  String get unread => _l10n.unread;
  String get allCaughtUp => _l10n.allCaughtUp;
  String get likedYourPost => _l10n.likedYourPost;
  String get commentedOnYourPost => _l10n.commentedOnYourPost;
  String get repliedToYourComment => _l10n.repliedToYourComment;
  String get itemAddedToCart => _l10n.itemAddedToCart;
  String get clearAll => _l10n.clearAll;
  String get clearAllNotifications => _l10n.clearAllNotifications;
  String get notification => _l10n.notification;
  
  // Bookmarks
  String get bookmarkedPosts => _l10n.bookmarkedPosts;
  String get noBookmarkedPosts => _l10n.noBookmarkedPosts;
  String get bookmarkPostsToSeeHere => _l10n.bookmarkPostsToSeeHere;
  
  // Search
  String get searchUsers => _l10n.searchUsers;
  String get searchPosts => _l10n.searchPosts;
  String get searchContent => _l10n.searchContent;
  
  // Profile
  String get thisAccountIsPrivate => _l10n.thisAccountIsPrivate;
  String get startCreatingContent => _l10n.startCreatingContent;
  
  // Create Post
  String get makeItFree => _l10n.makeItFree;
  String get publish => _l10n.publish;
  String get postCreatedSuccessfully => _l10n.postCreatedSuccessfully;
  String get selectType => _l10n.selectType;
  String get uploadCoverImage => _l10n.uploadCoverImage;
  String get coverImage => _l10n.coverImage;
  
  // Post Actions
  String get rateThisPost => _l10n.rateThisPost;
  String get addToBookmark => _l10n.addToBookmark;
  String get removeBookmark => _l10n.removeBookmark;
  String get reportPost => _l10n.reportPost;
  String get refresh => _l10n.refresh;
  String get tryAgain => _l10n.tryAgain;
  String get notificationsNotAvailable => _l10n.notificationsNotAvailable;
  
  // Create Post Screen
  String get createNewPost => _l10n.createNewPost;
  String get shareContentWithCommunity => _l10n.shareContentWithCommunity;
  String get chooseType => _l10n.chooseType;
  String get enterTitle => _l10n.enterTitle;
  String get readyToPost => _l10n.readyToPost;
  String get audioFile => _l10n.audioFile;
  String get videoFile => _l10n.videoFile;
  String get reelVideo => _l10n.reelVideo;
  String get document => _l10n.document;
  String get imageFile => _l10n.imageFile;
  String get uploadAudio => _l10n.uploadAudio;
  String get uploadReel => _l10n.uploadReel;
  String get uploadDocument => _l10n.uploadDocument;
  String get mp3WavUpTo50MB => _l10n.mp3WavUpTo50MB;
  String get mp4AviUpTo500MB => _l10n.mp4AviUpTo500MB;
  String get mp4AviUpTo50MBMax15Sec => _l10n.mp4AviUpTo50MBMax15Sec;
  String get pdfDocxSupported => _l10n.pdfDocxSupported;
  String get jpgPngSupported => _l10n.jpgPngSupported;
  String get pngJpgGifUpTo10MB => _l10n.pngJpgGifUpTo10MB;
  String get uploadCover => _l10n.uploadCover;
  String get wordPad => _l10n.wordPad;
  String get cropImage => _l10n.cropImage;
  String get imageCroppedReady => _l10n.imageCroppedReady;
  String get describeYourPost => _l10n.describeYourPost;

  // Reels Screen
  String get noReelsAvailable => _l10n.noReelsAvailable;
  String get createOrFollowToSeeReels => _l10n.createOrFollowToSeeReels;
  String get you => _l10n.you;
  String get unknown => _l10n.unknown;
  String get deletePost => _l10n.deletePost;
  String get deletePostConfirm => _l10n.deletePostConfirm;
  String get videoNotAvailable => _l10n.videoNotAvailable;

  // Settings Screen
  String get noWalletTransactions => _l10n.noWalletTransactions;
  String get walletTransactionHistoryDesc => _l10n.walletTransactionHistoryDesc;
  String get enter4DigitStreamId => _l10n.enter4DigitStreamId;
  String get setPrice => _l10n.setPrice;
  String get streamPoster => _l10n.streamPoster;
  String get noFileChosen => _l10n.noFileChosen;
  String get streamDescription => _l10n.streamDescription;
  String get liveStream => _l10n.liveStream;
  String get noPaymentHistory => _l10n.noPaymentHistory;
  String get paymentHistoryDesc => _l10n.paymentHistoryDesc;
  String get dateNotAvailable => _l10n.dateNotAvailable;
  String get noSubscriptionsFound => _l10n.noSubscriptionsFound;
  String get subscriptionHistoryDesc => _l10n.subscriptionHistoryDesc;
  String get active => _l10n.active;
  String get subscriber => _l10n.subscriber;
  String subscribedTo(String name) => _l10n.subscribedTo(name);
  String subscribedToYou(String name) => _l10n.subscribedToYou(name);
  String get contactSupportTitle => _l10n.contactSupport; 
  String get becomeCreator => _l10n.becomeCreator;
  String get becomeCreatorSubtitle => _l10n.becomeCreatorSubtitle;

  // Copyright & Publishing
  String get copyright => _l10n.copyright;
  String get publishing => _l10n.publishing;
  String get getCertificate => _l10n.getCertificate;
  String get requestCertificate => _l10n.requestCertificate;
  String get artistName => _l10n.artistName;
  String get writtenBy => _l10n.writtenBy;
  String get idCard => _l10n.idCard;
  String get browse => _l10n.browse;
  String get noFileSelected => _l10n.noFileSelected;
  String get iAcceptTerms => _l10n.iAcceptTerms;
  String get certificate => _l10n.certificate;
  String get termsAndConditions => _l10n.termsAndConditions;
  String get privacyPolicy => _l10n.privacyPolicy;
  String get publishedContent => _l10n.publishedContent;
  String get requestPublishing => _l10n.requestPublishing;
  String get publishingSubTitle => _l10n.publishingSubTitle;
  String get publishingContent => _l10n.publishingContent;
  String get enterContentToPublish => _l10n.enterContentToPublish;

  String get uploadFiles => _l10n.uploadFiles;
  String get processing => _l10n.processing;
  String get artistNameRequired => _l10n.artistNameRequired;
  String get writerNameRequired => _l10n.writerNameRequired;
  String get idCardRequired => _l10n.idCardRequired;
  String get acceptTermsRequired => _l10n.acceptTermsRequired;

  String getCertificateCount(int count) => _l10n.getCertificateCount(count);
  String publishSelectedCount(int count) => _l10n.publishSelectedCount(count);
  String selectedContentCount(int count) => _l10n.selectedContentCount(count);
  String createdOn(String date) => _l10n.createdOn(date);
  String publishedOn(String date) => _l10n.publishedOn(date);
  String filesSelectedCount(int count) => _l10n.filesSelectedCount(count);
  String get enterWriterName => _l10n.enterWriterName;
  String get contentSubmittedCopyright => _l10n.contentSubmittedCopyright;
  String get contentSubmittedPublishing => _l10n.contentSubmittedPublishing;
  String get iAcceptThe => _l10n.iAcceptThe;
  String get and => _l10n.and;
  String peopleCount(int count) => _l10n.peopleCount(count);
  String get messagingComingSoon => _l10n.messagingComingSoon;
  String get youHaveBlockedUser => _l10n.youHaveBlockedUser;
  String get unblockToSeePosts => _l10n.unblockToSeePosts;
  String get unblockBtn => _l10n.unblockBtn;
  String get appName => _l10n.appName;
  String get followRef => _l10n.followRef;
  String get noPostsFoundCategory => _l10n.noPostsFoundCategory;
  String get mediaPreviewNotAvailable => _l10n.mediaPreviewNotAvailable;
  String get untitled => _l10n.untitled;
  String get dots => _l10n.dots;
  String get dayShort => _l10n.dayShort;
  String get hourShort => _l10n.hourShort;
  String get minuteShort => _l10n.minuteShort;
  
  String monthShort(int month) {
    switch (month) {
      case 1: return _l10n.monthShortJan;
      case 2: return _l10n.monthShortFeb;
      case 3: return _l10n.monthShortMar;
      case 4: return _l10n.monthShortApr;
      case 5: return _l10n.monthShortMay;
      case 6: return _l10n.monthShortJun;
      case 7: return _l10n.monthShortJul;
      case 8: return _l10n.monthShortAug;
      case 9: return _l10n.monthShortSep;
      case 10: return _l10n.monthShortOct;
      case 11: return _l10n.monthShortNov;
      case 12: return _l10n.monthShortDec;
      default: return "";
    }
  }

  String likeNotification(int count, String postTitle) => _l10n.likeNotification(count, postTitle);
  String commentNotification(String author, String comment) => _l10n.commentNotification(author, comment);
  String replyNotification(String author, String comment) => _l10n.replyNotification(author, comment);

  // Albums
  String get playAlbum => _l10n.playAlbum;
  String get editAlbum => _l10n.editAlbum;
  String get deleteAlbum => _l10n.deleteAlbum;
  String get albumTitle => _l10n.albumTitle;
  String get enterAlbumTitle => _l10n.enterAlbumTitle;
  String get albumCover => _l10n.albumCover;
  String get fileSelected => _l10n.fileSelected;
  String get pngJpgGifUpTo2MB => _l10n.pngJpgGifUpTo2MB;
  String get selectTracks => _l10n.selectTracks;
  String get addTracksToAlbum => _l10n.addTracksToAlbum;
  String get tracks => _l10n.tracks;
  String tracksCount(int count) => _l10n.tracksCount(count);
  String albumCreated(String title) => _l10n.albumCreated(title);
  String get albumUpdated => _l10n.albumUpdated;
  String get albumDeleted => _l10n.albumDeleted;
  String get deselectAll => _l10n.deselectAll;
  String get selectAll => _l10n.selectAll;
  
  String get noAlbumsYet => _l10n.noAlbumsYet;
  String get createFirstAlbumDesc => _l10n.createFirstAlbumDesc;
  String get createYourFirstAlbum => _l10n.createYourFirstAlbum;
  String get unknownAlbum => _l10n.unknownAlbum;
  String get songsPlural => _l10n.songsPlural;
  String get videosPlural => _l10n.videosPlural;
  String get noMediaFound => _l10n.noMediaFound;
  String get updateAlbum => _l10n.updateAlbum;
  String get albumDetails => _l10n.albumDetails;

  
  String get audioUnavailable => _l10n.audioUnavailable;
  String get audioFileAttached => _l10n.audioFileAttached;
  String get videoError => _l10n.videoError;
  String get errorLoadingVideo => _l10n.errorLoadingVideo;
  String get retry => _l10n.retry;
  String get imageNotFound => _l10n.imageNotFound;
  String get failedToLoadImage => _l10n.failedToLoadImage;
  String get audioFileNotFound => _l10n.audioFileNotFound;
  String get fileNotAvailable => _l10n.fileNotAvailable;
  String get failedToLoadPdf => _l10n.failedToLoadPdf;
  String get pdfFileNotFound => _l10n.pdfFileNotFound;
  String errorLoadingPdf(String error) => _l10n.errorLoadingPdf(error);
  String get deleteAlbumConfirmation => _l10n.deleteAlbumConfirmation;
  String get year => _l10n.year;

  String get freePostsNoCart => _l10n.freePostsNoCart;
  String get ownPostsNoCart => _l10n.ownPostsNoCart;
  String get alreadyInCart => _l10n.alreadyInCart;
  String get linkCopied => _l10n.linkCopied;
  String get reportSubmitted => _l10n.reportSubmitted;
  String get fillRequiredFields => _l10n.fillRequiredFields;
  String get commentDeleted => _l10n.commentDeleted;
  String get commentNotEmpty => _l10n.commentNotEmpty;
  String get ratingSubmitted => _l10n.ratingSubmitted;
  String get bookmarkRemoved => _l10n.bookmarkRemoved;
  String get postBookmarked => _l10n.postBookmarked;
  String get categoryRequired => _l10n.categoryRequired;
  String get contentRequired => _l10n.contentRequired;
  String get selectUserToLogin => _l10n.selectUserToLogin;
  String get simulateLoginDesc => _l10n.simulateLoginDesc;
  String loginAsUser(String name) => _l10n.loginAsUser(name);
  String get chooseYourLanguage => _l10n.chooseYourLanguage;
  String get uploadFile => _l10n.uploadFile;
  String get createPostBtn => _l10n.createPostBtn;
  String get saving => _l10n.saving;
  String get noContentAvailable => _l10n.noContentAvailable;
  String get writeSomething => _l10n.writeSomething;
  String get creatingPost => _l10n.creatingPost;
  String get postCreated => _l10n.postCreated;
  String errorSavingPost(String error) => _l10n.errorSavingPost(error);
  String get loggingOut => _l10n.loggingOut;
  String errorAddingToCart(String error) => _l10n.errorAddingToCart(error);
  String get postNoLongerAvailable => _l10n.postNoLongerAvailable;
  String get addTracks => _l10n.addTracks;
  String get doneAdding => _l10n.doneAdding;
  String get noTracksSelected => _l10n.noTracksSelected;
  String get addMoreTracks => _l10n.addMoreTracks;
  String liveStreamsCount(int count) => _l10n.liveStreamsCount(count);
  String refreshedStreams(int count) => _l10n.refreshedStreams(count);
  String get startStreamingBtn => _l10n.startStreamingBtn;
  String get goLiveBtn => _l10n.goLiveBtn;
  String get end => _l10n.end;
  String get beTheFirstToSayHello => _l10n.beTheFirstToSayHello;
  String get people => _l10n.people;
  String get newPost => _l10n.newPost;
  String get submitRating => _l10n.submitRating;
  String get couldNotLoadPdf => _l10n.couldNotLoadPdf;
  String get pdfNotFound => _l10n.pdfNotFound;
  String get couldNotLoadPreview => _l10n.couldNotLoadPreview;
  String get openFullPdf => _l10n.openFullPdf;
  String get imageNotAvailable => _l10n.imageNotAvailable;
  String get postUnavailable => _l10n.postUnavailable;
  String get postCouldNotBeFound => _l10n.postCouldNotBeFound;
  String get invalidImagePath => _l10n.invalidImagePath;
  String get addTracksBtn => _l10n.addTracksBtn;
  String get selectedTracks => _l10n.selectedTracks;
  String get noSongsOrVideosFound => _l10n.noSongsOrVideosFound;
  String get noCommentsYetBeFirst => _l10n.noCommentsYetBeFirst;
  String get noCommentsYet => _l10n.noCommentsYet;
  String get replyingTo => _l10n.replyingTo;
  String get legalFullName => _l10n.legalFullName;
  String get enterYourFullName => _l10n.enterYourFullName;
  String get enterYourUsername => _l10n.enterYourUsername;
  String get tellUsAboutYourself => _l10n.tellUsAboutYourself;
  String get user => _l10n.user;
  String get host => _l10n.host;
  String get untitledStream => _l10n.untitledStream;
  String get shareYourThoughts => _l10n.shareYourThoughts;
  String get clickToRate => _l10n.clickToRate;
  String get country => _l10n.country;
  String get state => _l10n.state;
  String get city => _l10n.city;
  String get stream => _l10n.stream;
  String get unknownError => _l10n.unknownError;
  String get more => _l10n.more;
  String get reportPostFormTitle => _l10n.reportPostFormTitle;
  String get categoryRequiredHint => _l10n.categoryRequiredHint;
  String get contentRequiredHint => _l10n.contentRequiredHint;
  String get selectCategory => _l10n.selectCategory;
  String get categorySpam => _l10n.categorySpam;
  String get categoryInappropriate => _l10n.categoryInappropriate;
  String get categoryHarassment => _l10n.categoryHarassment;
  String get categoryFalseInfo => _l10n.categoryFalseInfo;
  String get categoryCopyright => _l10n.categoryCopyright;
  String get categoryOther => _l10n.categoryOther;
  String get enterDescription => _l10n.enterDescription;
  String errorPostingComment(Object error) => _l10n.errorPostingComment(error);
  String itemOutOfStock(Object item) => _l10n.itemOutOfStock(item);
  String commentsCount(Object count) => _l10n.commentsCount(count);
  String get beFirstToComment => _l10n.beFirstToComment;
  String get authorLabel => _l10n.authorLabel;
  String get addCommentPlaceholder => _l10n.addCommentPlaceholder;
  String get followerLabel => _l10n.followerLabel;
  String get followingLabel => _l10n.followingLabel;

  // New keys added for Settings & Profile
  String get amount => _l10n.amount;
  String get tax => _l10n.tax;
  String get type => _l10n.type;
  String get recipient => _l10n.recipient;
  String get gateway => _l10n.gateway;
  String get status => _l10n.status;
  String get reference => _l10n.reference;
  String get date => _l10n.date;
  String get passwordSetSuccessfully => _l10n.passwordSetSuccessfully;
  String get fillAllPasswordFields => _l10n.fillAllPasswordFields;
  String get passwordsDoNotMatch => _l10n.passwordsDoNotMatch;
  String get changePassword => _l10n.changePassword;
  String get currentPassword => _l10n.currentPassword;
  String get newPassword => _l10n.newPassword;
  String get confirmNewPassword => _l10n.confirmNewPassword;
  String get enterCurrentPassword => _l10n.enterCurrentPassword;
  String get enterNewPassword => _l10n.enterNewPassword;
  String get confirmNewPasswordHint => _l10n.confirmNewPasswordHint;
  String get savePassword => _l10n.savePassword;
  String get paymentReceived => _l10n.paymentReceived;
  String get paymentSent => _l10n.paymentSent;
  String get gatewayStripe => _l10n.gatewayStripe;
  String get gatewayWallet => _l10n.gatewayWallet;
  String get paymentStatusCompleted => _l10n.paymentStatusCompleted;
  String get paymentStatusPending => _l10n.paymentStatusPending;
  String get unlockPost => _l10n.unlockPost;
  String get unlockContentDesc => _l10n.unlockContentDesc;
  String unlockFor(String price) => _l10n.unlockFor(price);
  String get watchPreview => _l10n.watchPreview;
  String get preview => _l10n.preview;
  String get editPost => _l10n.editPost;
  String get updatePost => _l10n.updatePost;
  String get shareContentEdit => _l10n.shareContentEdit;
  String get postUpdated => _l10n.postUpdated;
  String get previewVideo => _l10n.previewVideo;
  String get previewAudio => _l10n.previewAudio;
  String get uploadPreview => _l10n.uploadPreview;
  String get subscribeToUnlock => _l10n.subscribeToUnlock;
  
  // Tip Dialog
  String get tipAmount => _l10n.tipAmount;
  String get tipAmountMinMax => _l10n.tipAmountMinMax;

  String get time => _l10n.time;
  String get selectPaymentMethod => _l10n.selectPaymentMethod;

  String get card => _l10n.card;
  String get securePayment => _l10n.securePayment;
  String sendTip(Object amount) => _l10n.sendTip(amount);
  String tipSent(Object amount) => _l10n.tipSent(amount);
  String get minTipAmount => _l10n.minTipAmount;
  String get maxTipAmount => _l10n.maxTipAmount;
  String get negativeAmountError => _l10n.negativeAmountError;
  String get maxAmountError => _l10n.maxAmountError;
  String artistRate(Object rate) => _l10n.artistRate(rate);
  String get tip => _l10n.tip;
  
  // Subscriptions
  String get totalEarnings => _l10n.totalEarnings;
  String get activeSubscribers => _l10n.activeSubscribers;
  String get yourSubscriptions => _l10n.yourSubscriptions;
  String get totalSubscriptions => _l10n.totalSubscriptions;
  String get subscribers => _l10n.subscribers;
  String get subscriptionType => _l10n.subscriptionType;
  String get provider => _l10n.provider;
  String get nextBilling => _l10n.nextBilling;
  String get created => _l10n.created;
  String get noSubscribersFound => _l10n.noSubscribersFound;
  String get subscriberListDesc => _l10n.subscriberListDesc;
  String get yourSubscribersList => _l10n.yourSubscribersList;
  
  // Rate & Time
  String get rateMustBeBetween => _l10n.rateMustBeBetween;
  String get rateUpdated => _l10n.rateUpdated;
  String get updateRate => _l10n.updateRate;
  String get rateSetToFree => _l10n.rateSetToFree;
  String get makeFree => _l10n.makeFree;
  String get timeMustBeBetween => _l10n.timeMustBeBetween;
  String get timeUpdated => _l10n.timeUpdated;
  String get updateTime => _l10n.updateTime;
  String get disconnectionDisabled => _l10n.disconnectionDisabled;
  String get disableDisconnection => _l10n.disableDisconnection;
  
  // Settings
  String get notificationSettingsSaved => _l10n.notificationSettingsSaved;
  String get allowNotifications => _l10n.allowNotifications;
  String get notificationNewLike => _l10n.notificationNewLike;
  String get notificationNewSub => _l10n.notificationNewSub;
  String get notificationTip => _l10n.notificationTip;
  String get notificationMessage => _l10n.notificationMessage;
  String get notificationComment => _l10n.notificationComment;
  String get notificationExpiringSub => _l10n.notificationExpiringSub;
  String get notificationRenewal => _l10n.notificationRenewal;
  
  // Create Post
  String get deletePostQuestion => _l10n.deletePostQuestion;
  String get deletePostConfirmation => _l10n.deletePostConfirmation;
  String get deleteButton => _l10n.deleteButton;
  
  // Main Content Area
  String get sentToOzVault => _l10n.sentToOzVault;
  String get sendToOzVault => _l10n.sendToOzVault;
  String limitReachedAudio(Object current, Object limit) => _l10n.limitReachedAudio(current, limit);
  String limitReachedVideo(Object current, Object limit) => _l10n.limitReachedVideo(current, limit);
  String unfollowed(Object name) => _l10n.unfollowed(name);
  String get unableToUnfollow => _l10n.unableToUnfollow;
  String blocked(Object name) => _l10n.blocked(name);
  
  // Edit Profile
  String get noOptionsAvailable => _l10n.noOptionsAvailable;
  
  // Login
  String failedToLogin(Object error) => _l10n.failedToLogin(error);
  
  // Top Search Bar
  String get cartNotAvailable => _l10n.cartNotAvailable;
  
  // Misc UI
  String get artist => _l10n.artist;
  String get messageHint => _l10n.messageHint;
  String get requiredField => _l10n.requiredField;
  
  // FAQ
  String get faq => _l10n.faq;
  String get findAnswers => _l10n.findAnswers;
  String get faqQ1 => _l10n.faqQ1;
  String get faqA1 => _l10n.faqA1;
  String get faqQ2 => _l10n.faqQ2;
  String get faqA2 => _l10n.faqA2;
  String get faqQ3 => _l10n.faqQ3;
  String get faqA3 => _l10n.faqA3;
  String get faqQ4 => _l10n.faqQ4;
  String get faqA4 => _l10n.faqA4;
  String get faqQ5 => _l10n.faqQ5;
  String get faqA5 => _l10n.faqA5;
  String get faqQ6 => _l10n.faqQ6;
  String get faqA6 => _l10n.faqA6;

  // Rate & Time
  String get rates => _l10n.rates;
  String get currentRate => _l10n.currentRate;
  String get profileSubscriptionPrice => _l10n.profileSubscriptionPrice;
  String get setNewRate => _l10n.setNewRate;
  String get enterNewRateHint => _l10n.enterNewRateHint;
  String get currentTime => _l10n.currentTime;
  String get callCenterTimingDesc => _l10n.callCenterTimingDesc;
  String get setNewTimeMinutes => _l10n.setNewTimeMinutes;
  String get enterMinutesHint => _l10n.enterMinutesHint;
  String get notSet => _l10n.notSet;
  
  // Snackbars
  String get postLiked => _l10n.postLiked;
  String get postUnliked => _l10n.postUnliked;
  String get commentPosted => _l10n.commentPosted;
  String get postDeleted => _l10n.postDeleted;
  String get postUpdatedSnack => _l10n.postUpdatedSnack;

  // Verification
  String get verification => _l10n.verification;
  String get verificationSubtitle => _l10n.verificationSubtitle;
  String get verificationDesc => _l10n.verificationDesc;
  String get confirmEmail => _l10n.confirmEmail;
  String get emailVerifiedSuccess => _l10n.emailVerifiedSuccess;
  String get verifyEmailDesc => _l10n.verifyEmailDesc;
  String get verifiedBtn => _l10n.verifiedBtn;
  String get verifyBtn => _l10n.verifyBtn;
  String get becomeArtist => _l10n.becomeArtist;
  String get becomeArtistDesc => _l10n.becomeArtistDesc;
  String get becomeArtistInstructions => _l10n.becomeArtistInstructions;
  String get govIdFront => _l10n.govIdFront;
  String get govIdFrontDesc => _l10n.govIdFrontDesc;
  String get govIdBack => _l10n.govIdBack;
  String get govIdBackDesc => _l10n.govIdBackDesc;
  String get livePhoto => _l10n.livePhoto;
  String get livePhotoDesc => _l10n.livePhotoDesc;
  String get convertToArtist => _l10n.convertToArtist;
  String get takeAllPhotos => _l10n.takeAllPhotos;
  String get verificationSubmitted => _l10n.verificationSubmitted;
  String errorPickingImage(Object error) => _l10n.errorPickingImage(error);
  String get cartUpdated => _l10n.cartUpdated;
  
  // Rating Dialog
  String get ratingPoor => _l10n.ratingPoor;
  String get ratingFair => _l10n.ratingFair;
  String get ratingGood => _l10n.ratingGood;
  String get ratingVeryGood => _l10n.ratingVeryGood;
  String get ratingExcellent => _l10n.ratingExcellent;
  String get averageRating => _l10n.averageRating;
  String get totalRatings => _l10n.totalRatings;
  
  // Create/Edit Post
  String get editPostTitle => _l10n.editPostTitle;
  String get readyToUpdate => _l10n.readyToUpdate;
  String get reviewAndUpdate => _l10n.reviewAndUpdate;
  String get updatePostBtn => _l10n.updatePostBtn;
  String get shortTeaserMax10s => _l10n.shortTeaserMax10s;
  String get cropImageTitle => _l10n.cropImageTitle;
  


  // Notifications
  String get tipReceived => _l10n.tipReceived;
  String get newSubscriber => _l10n.newSubscriber;
  String get newMessage => _l10n.newMessage;

  // Profile
  String get online => _l10n.online;
  String get offline => _l10n.offline;
  String joined(Object date) => _l10n.joined(date);
  String get welcomeProfile => _l10n.welcomeProfile;
  String get genderMale => _l10n.genderMale;
  String get genderFemale => _l10n.genderFemale;
  String get genderOther => _l10n.genderOther;
  String get monthFullJan => _l10n.monthFullJan;
  String get monthFullFeb => _l10n.monthFullFeb;
  String get monthFullMar => _l10n.monthFullMar;
  String get monthFullApr => _l10n.monthFullApr;
  String get monthFullMay => _l10n.monthFullMay;
  String get monthFullJun => _l10n.monthFullJun;
  String get monthFullJul => _l10n.monthFullJul;
  String get monthFullAug => _l10n.monthFullAug;
  String get monthFullSep => _l10n.monthFullSep;
  String get monthFullOct => _l10n.monthFullOct;
  String get monthFullNov => _l10n.monthFullNov;
  String get monthFullDec => _l10n.monthFullDec;
  String get streamArtist => _l10n.streamArtist;
  String get followArtistToUnlock => _l10n.followArtistToUnlock;
  String get hidden => _l10n.hidden;
  String get followToSeeContent => _l10n.followToSeeContent;
  String get contentDetails => _l10n.contentDetails;
  String get sizeLabel => _l10n.sizeLabel;
  String get notAvailable => _l10n.notAvailable;
  String get dimension => _l10n.dimension;
  String get uploadedOn => _l10n.uploadedOn;

  String get subscribed => _l10n.subscribed;
  String subscribePrice(Object price) => _l10n.subscribePrice(price);
  String get all => _l10n.all;
  String shareProfileText(Object name, Object url) => _l10n.shareProfileText(name, url);
  String get shareProfileSubject => _l10n.shareProfileSubject;
  String get on => _l10n.on;
  String get off => _l10n.off;
  String get font => _l10n.font;
  String get lockedContent => _l10n.lockedContent;
  String get tapToOpenFile => _l10n.tapToOpenFile;
  String get subscribeToAccess => _l10n.subscribeToAccess;
  String get writingText => _l10n.writingText;





  static const List<Map<String, dynamic>> ALL_LANGUAGES = [
    {'code': 'en', 'name': 'English (US)', 'native': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Spanish (Spain)', 'native': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French (France)', 'native': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German (Germany)', 'native': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian (Italy)', 'native': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portuguese (Portugal)', 'native': 'Português', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Russian (Russia)', 'native': 'Русский', 'flag': '🇷🇺'},
    {'code': 'zh', 'name': 'Chinese (Simplified)', 'native': '简体中文', 'flag': '🇨🇳'},
    {'code': 'zh_Hant', 'name': 'Chinese (Traditional)', 'native': '繁體中文', 'flag': '🇹🇼'},
    {'code': 'ja', 'name': 'Japanese (Japan)', 'native': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean (South Korea)', 'native': '한국어', 'flag': '🇰🇷'},
    {'code': 'hi', 'name': 'Hindi (India)', 'native': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'Arabic (Saudi Arabia)', 'native': 'العربية', 'flag': '🇸🇦'},
    {'code': 'th', 'name': 'Thai (Thailand)', 'native': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'vi', 'name': 'Vietnamese (Vietnam)', 'native': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'nl', 'name': 'Dutch (Netherlands)', 'native': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'sv', 'name': 'Swedish (Sweden)', 'native': 'Svenska', 'flag': '🇸🇪'},
    {'code': 'no', 'name': 'Norwegian (Norway)', 'native': 'Norsk', 'flag': '🇳🇴'},
    {'code': 'da', 'name': 'Danish (Denmark)', 'native': 'Dansk', 'flag': '🇩🇰'},
    {'code': 'fi', 'name': 'Finnish (Finland)', 'native': 'Suomi', 'flag': '🇫🇮'},
    {'code': 'pl', 'name': 'Polish (Poland)', 'native': 'Polski', 'flag': '🇵🇱'},
    {'code': 'cs', 'name': 'Czech (Czechia)', 'native': 'Čeština', 'flag': '🇨🇿'},
    {'code': 'hu', 'name': 'Hungarian (Hungary)', 'native': 'Magyar', 'flag': '🇭🇺'},
    {'code': 'ro', 'name': 'Romanian (Romania)', 'native': 'Română', 'flag': '🇷🇴'},
    {'code': 'el', 'name': 'Greek (Greece)', 'native': 'Ελληνικά', 'flag': '🇬🇷'},
    {'code': 'tr', 'name': 'Turkish (Turkey)', 'native': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'id', 'name': 'Indonesian (Indonesia)', 'native': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'ms', 'name': 'Malay (Malaysia)', 'native': 'Bahasa Melayu', 'flag': '🇲🇾'},
    {'code': 'fil', 'name': 'Filipino (Philippines)', 'native': 'Filipino', 'flag': '🇵🇭'},
    {'code': 'sw', 'name': 'Swahili (East Africa)', 'native': 'Kiswahili', 'flag': '🇰🇪'},
    {'code': 'ur', 'name': 'Urdu (Pakistan)', 'native': 'اردو', 'flag': '🇵🇰'},
    {'code': 'bn', 'name': 'Bengali (Bangladesh)', 'native': 'বাংলা', 'flag': '🇧🇩'},
  ];

  /// Quick access method - use this in any widget
  static AppTranslations of(BuildContext context) => AppTranslations(context);
}

/// Extension to make translations even easier to access
extension TranslationExtension on BuildContext {
  AppTranslations get tr => AppTranslations.of(this);
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
