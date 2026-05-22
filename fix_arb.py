
import re
import json

# Known values from previous file reads
known_values = {
  "appTitle": "OpenZippers",
  "home": "Home",
  "explore": "Explore",
  "add": "Add",
  "reels": "Reels",
  "live": "Live",
  "profile": "Profile",
  "settings": "Settings",
  "language": "Language",
  "selectLanguage": "Select Language",
  "darkMode": "Dark Mode",
  "lightMode": "Light Mode",
  "logout": "Logout",
  "confirmLogout": "Are you sure you want to logout?",
  "cancel": "Cancel",
  "ok": "OK",
  "streaming": "STREAMING",
  "connections": "Connections",
  "search": "Search",
  "liveStreams": "Live Streams",
  "bookmark": "Bookmark",
  "cart": "Cart",
  "gallery": "Gallery",
  "camera": "Camera",
  "helpSupport": "Help & Support",
  "like": "Like",
  "comment": "Comment",
  "share": "Share",
  "save": "Save",
  "delete": "Delete",
  "edit": "Edit",
  "post": "Post",
  "submit": "Submit",
  "confirm": "Confirm",
  "back": "Back",
  "next": "Next",
  "done": "Done",
  "close": "Close",
  "changeFile": "Change File",
  "followers": "Followers",
  "follower": "Follower",
  "following": "Following",
  "posts": "Posts",
  "editProfile": "Edit Profile",
  "bio": "Bio",
  "about": "About",
  "verified": "Verified",
  "likes": "Likes",
  "comments": "Comments",
  "shares": "Shares",
  "views": "Views",
  "reads": "Reads",
  "justNow": "Just now",
  "minutesAgo": "{count} minutes ago",
  "hoursAgo": "{count} hours ago",
  "daysAgo": "{count} days ago",
  "weeksAgo": "{count} weeks ago",
  "monthsAgo": "{count} months ago",
  "title": "Title",
  "description": "Description",
  "content": "Content",
  "price": "Price",
  "free": "Free",
  "suggestions": "Suggestions",
  "paid": "Paid",
  "image": "Image",
  "video": "Video",
  "song": "Song",
  "literature": "Literature",
  "reel": "Reel",
  "genre": "Genre",
  "selectGenre": "Select Genre",
  "uploadImage": "Upload Image",
  "uploadVideo": "Upload Video",
  "chooseFile": "Choose File",
  "enterText": "Enter text",
  "searchPlaceholder": "Search...",
  "addToCart": "Add to Cart",
  "removeFromCart": "Remove from Cart",
  "checkout": "Checkout",
  "total": "Total",
  "subtotal": "Subtotal",
  "error": "Error",
  "success": "Success",
  "warning": "Warning",
  "loading": "Loading",
  "pleaseWait": "Please wait...",
  "enterTitleError": "Please enter a Title",
  "contentProcessingError": "Error processing content. Please try again.",
  "uploadPdfError": "Please upload a PDF file for Literature post",
  "pdfFileNotExistError": "Selected PDF file does not exist. Please try uploading again.",
  "notPdfError": "Please upload a PDF file. Selected file is not a PDF.",
  "pdfValidationError": "Error validating PDF file. Please try uploading again.",
  "writeContentError": "Please write content",
  "uploadFileError": "Please upload the {fileType} file",
  "fileNotExistError": "Selected file does not exist. Please try uploading again.",
  "fileValidationError": "Error validating file. Please try uploading again.",
  "uploadCoverImageError": "Please upload a cover image",
  "errorCreatingPost": "Error creating post: {error}",
  "selectLanguageError": "Please select a language",
  "langEnglish": "English",
  "langSpanish": "Spanish",
  "langFrench": "French",
  "langGerman": "German",
  "audio": "Audio",
  "imageLabel": "image",
  "videoLabel": "video",
  "audioLabel": "audio",
  "tip": "Tip",
  "artist": "Artist",
  "messageHint": "Message...",
  "requiredField": " *",
  "tipAmount": "Tip Amount",
  "sendTip": "Send {amount}",
  "tipSent": "Tip of {amount} sent!",
  "minTipAmount": "Min tip amount is $1",
  "maxTipAmount": "Max tip amount is $5000",
  "unfollowed": "Unfollowed {name}",
  "blocked": "Blocked {name}",
  "cartNotAvailable": "Cart is not available",
  "failedToLogin": "Failed to login: {error}",
  "noOptionsAvailable": "No options available",
  "sentToOzVault": "Sent to Oz Vault",
  "sendToOzVault": "Send To OzVault",
  "limitReachedAudio": "Limit Reached: {current}/{limit} Audio Tracks",
  "limitReachedVideo": "Limit Reached: {current}/{limit} Video Files",
  "unableToUnfollow": "Unable to unfollow user",
  "deletePostQuestion": "Delete Post?",
  "deletePostConfirmation": "Are you sure you want to delete this post?",
  "deleteButton": "Delete",
  "notificationSettingsSaved": "Notification settings saved",
  "rateMustBeBetween": "Rate must be between 5 and 100",
  "rateUpdated": "Rate Updated!",
  "updateRate": "Update Rate",
  "rateSetToFree": "Rate set to Free!",
  "makeFree": "Make Free",
  "timeMustBeBetween": "Time must be between 0 and 60 minutes",
  "timeUpdated": "Time Updated!",
  "updateTime": "Update Time",
  "disconnectionDisabled": "Disconnection Disabled!",
  "disableDisconnection": "Disable Disconnection",
  "totalEarnings": "Total Earnings",
  "activeSubscribers": "Active Subscribers",
  "yourSubscriptions": "Your Subscriptions",
  "totalSubscriptions": "Total Subscriptions",
  "subscribers": "Subscribers",
  "subscriptionType": "Subscription Type",
  "provider": "Provider",
  "nextBilling": "Next Billing",
  "created": "Created",
  "noSubscribersFound": "No subscribers found.",
  "subscriberListDesc": "Your subscriber list will appear here once someone subscribes to you.",
  "yourSubscribersList": "Your Subscribers",
  "tipAmountMinMax": "Tip Amount (min $1, max $5000)",
  "quickAmounts": "Quick amounts",
  "time": "Time",
  "selectPaymentMethod": "Select payment method",
  "wallet": "Wallet",
  "card": "Card",
  "securePayment": "Secure payment",
  "negativeAmountError": "You cannot enter a negative amount",
  "maxAmountError": "You cannot enter more than $5000",
  "artistRate": "Artist Rate: {rate}/hr",
  
  "monthShortJan": "Jan",
  "monthShortFeb": "Feb",
  "monthShortMar": "Mar",
  "monthShortApr": "Apr",
  "monthShortMay": "May",
  "monthShortJun": "Jun",
  "monthShortJul": "Jul",
  "monthShortAug": "Aug",
  "monthShortSep": "Sep",
  "monthShortOct": "Oct",
  "monthShortNov": "Nov",
  "monthShortDec": "Dec",
  
  "payForAvailableItemsPlural": "Pay for {count} available items",
  "payForAvailableItems": "Pay for {count} available item",
}

# Scan translations.dart for keys
keys = []
with open('lib/helpers/translations.dart', 'r') as f:
    content = f.read()
    
    # Match basic getters: String get keyName => _l10n.keyName;
    getters = re.findall(r'String get (\w+)\s*=>\s*_l10n\.\1', content)
    keys.extend(getters)
    
    # Match methods: String methodName(args) => _l10n.methodName(args);
    methods = re.findall(r'String (\w+)\(.*\)\s*=>\s*_l10n\.\1', content)
    keys.extend(methods)

# Create ARB content
arb_data = {
    "@@locale": "en"
}

for key in keys:
    if key in known_values:
        arb_data[key] = known_values[key]
    else:
        # Generate dummy value but respect placeholders if any
        # Check if it was a method call to guess placeholders
        method_match = re.search(r'String ' + key + r'\(([^)]*)\)', content)
        if method_match:
            args = method_match.group(1)
            # clear types
            args = re.sub(r'String\s+|int\s+|double\s+|Object\s+', '', args)
            placeholders = [p.strip().split(' ')[0] for p in args.split(',') if p.strip()]
            
            # Create a simple default value like "keyName {arg1} {arg2}"
            value = key + " " + " ".join(["{" + p + "}" for p in placeholders])
            
            placeholders_map = {}
            for p in placeholders:
                if p:
                  placeholders_map[p] = {}
            
            arb_data[key] = value
            arb_data["@" + key] = {
                "placeholders": placeholders_map
            }
        else:
            arb_data[key] = key # Default to key name for now

# Add manually managed keys that might have been missed by regex
for k, v in known_values.items():
    if k not in arb_data:
        arb_data[k] = v

# Write to file
with open('lib/l10n/app_en.arb', 'w') as f:
    json.dump(arb_data, f, indent=2)

print(f"Restored {len(arb_data)} keys to app_en.arb")
