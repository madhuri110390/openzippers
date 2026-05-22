import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mock_data.dart';
import '../helpers/database_helper.dart';
import '../l10n/generated/app_localizations.dart';
import '../helpers/translations.dart';
import '../main.dart';
import 'wallet_screen.dart';

import 'payment_history_screen.dart';
import 'subscriptions_page.dart';
import 'creator_verification_screen.dart';
import '../widgets/contact_support_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final MockUser currentUser;
  final Function(MockUser) onSave;
  final VoidCallback onBack;
  final VoidCallback? onThemeTap;
  final VoidCallback? onFaqTap;
  final VoidCallback? onLogoutTap;
  final bool? notificationsEnabled;
  final bool? likeNotificationsEnabled;
  final bool? commentNotificationsEnabled;
  final bool? newSubNotificationsEnabled;
  final bool? tipNotificationsEnabled;
  final bool? messageNotificationsEnabled;
  final bool? expiringSubNotificationsEnabled;
  final bool? upcomingRenewalNotificationsEnabled;
  final Function(bool, bool, bool, bool, bool, bool, bool, bool)? onNotificationSettingsChanged;
  const SettingsScreen({
    super.key,
    required this.currentUser,
    required this.onSave,
    required this.onBack,
    this.onThemeTap,
    this.onFaqTap,
    this.onLogoutTap,
    this.notificationsEnabled,
    this.likeNotificationsEnabled,
    this.commentNotificationsEnabled,
    this.newSubNotificationsEnabled,
    this.tipNotificationsEnabled,
    this.messageNotificationsEnabled,
    this.expiringSubNotificationsEnabled,
    this.upcomingRenewalNotificationsEnabled,
    this.onNotificationSettingsChanged,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late bool _notificationsEnabled; // Kept for legacy compatibility if needed
  late bool _likeNotificationsEnabled;
  late bool _commentNotificationsEnabled;

  // Granular Notification Settings
  bool _newSubNotifications = true;
  bool _tipNotifications = true;
  bool _messageNotifications = true;
  bool _expiringSubNotifications = false;
  bool _upcomingRenewalNotifications = false;

  // Expansion States
  bool _isGettingStartedExpanded = false;
  bool _isFaqExpanded = false;
  
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notificationsEnabled = widget.notificationsEnabled ?? true;
    _likeNotificationsEnabled = widget.likeNotificationsEnabled ?? true;
    _commentNotificationsEnabled = widget.commentNotificationsEnabled ?? true;
    _newSubNotifications = widget.newSubNotificationsEnabled ?? true;
    _tipNotifications = widget.tipNotificationsEnabled ?? true;
    _messageNotifications = widget.messageNotificationsEnabled ?? true;
    _expiringSubNotifications = widget.expiringSubNotificationsEnabled ?? false;
    _upcomingRenewalNotifications = widget.upcomingRenewalNotificationsEnabled ?? false;
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 800 ? 800.0 : constraints.maxWidth;
            final isSmallScreen = constraints.maxWidth < 600;
            
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  children: [
                    // FIXED HEADER
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 24,
                        vertical: 16
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: widget.onBack,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark 
                                    ? Colors.white.withValues(alpha: 0.05) 
                                    : const Color(0xFFDB2777).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.arrow_back, color: Color(0xFFDB2777), size: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr.settings, 
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 20 : 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: theme.textTheme.titleLarge?.color
                                  )
                                ),
                                Text(
                                  context.tr.manageAccountSubtitle, 
                                  style: TextStyle(color: theme.hintColor, fontSize: 12)
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
                    
                    // SCROLLABLE CONTENT
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 24,
                          vertical: 20
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSettingsContent(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildSettingsContent() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(context.tr.language, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              ),
              const SizedBox(width: 15,height: 15),
              _buildLanguageSelector(theme),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr.theme, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 15),
              _buildThemeToggle(theme),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_outlined, color: Color(0xFFDB2777), size: 24),
                  const SizedBox(width: 16),
                  Text(
                    context.tr.notifications,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildDetailedNotificationRow(context.tr.allowNotifications, _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
              _buildDetailedNotificationRow(context.tr.notificationNewLike, _likeNotificationsEnabled, (v) => setState(() => _likeNotificationsEnabled = v)),
              _buildDetailedNotificationRow(context.tr.notificationNewSub, _newSubNotifications, (v) => setState(() => _newSubNotifications = v)),
              _buildDetailedNotificationRow(context.tr.notificationTip, _tipNotifications, (v) => setState(() => _tipNotifications = v)),
              _buildDetailedNotificationRow(context.tr.notificationMessage, _messageNotifications, (v) => setState(() => _messageNotifications = v)),
              _buildDetailedNotificationRow(context.tr.notificationComment, _commentNotificationsEnabled, (v) => setState(() => _commentNotificationsEnabled = v)),
              _buildDetailedNotificationRow(context.tr.notificationExpiringSub, _expiringSubNotifications, (v) => setState(() => _expiringSubNotifications = v)),
              _buildDetailedNotificationRow(context.tr.notificationRenewal, _upcomingRenewalNotifications, (v) => setState(() => _upcomingRenewalNotifications = v), isLast: true),

              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                     // Save logic would go here
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(context.tr.notificationSettingsSaved), duration: const Duration(seconds: 1)),
                     );
                     _saveNotificationSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDB2777),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(context.tr.saveChanges),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.contact_support_outlined, color: Color(0xFFDB2777), size: 24),
                  const SizedBox(width: 16),
                  Text(
                    context.tr.helpSupport,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color
                    )
                  ),
                ],
              ),
              const SizedBox(height: 15),

              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ContactSupportDialog(),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        color: Color(0xFFDB2777),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.contactSupport,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.getInTouch,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: theme.hintColor),
                    ],
                  ),
                ),
              ),


              // Getting Started Section
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isGettingStartedExpanded = expanded;
                      });
                    },
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.auto_stories_outlined, color: Color(0xFFDB2777), size: 24),
                    trailing: Icon(
                      Icons.keyboard_arrow_down, 
                      color: _isGettingStartedExpanded 
                        ? const Color(0xFFDB2777) 
                        : (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
                    ),
                    title: Text(
                      context.tr.gettingStarted,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      context.tr.learnBasics,
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    children: [
                      _FaqItem(question: context.tr.creatingAccount, answer: context.tr.creatingAccountDesc),
                      _FaqItem(question: context.tr.exploringPlatform, answer: context.tr.exploringPlatformDesc),
                      _FaqItem(question: context.tr.setupProfile, answer: context.tr.setupProfileDesc),
                    ],
                  ),
                ),
              ),

              // FAQ Section
              Container(
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _isFaqExpanded = expanded;
                      });
                    },
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: const Icon(Icons.help_outline, color: Color(0xFFDB2777), size: 24),
                    trailing: Icon(
                      Icons.keyboard_arrow_down, 
                      color: _isFaqExpanded 
                        ? const Color(0xFFDB2777) 
                        : (theme.brightness == Brightness.dark ? Colors.white : Colors.black)
                    ),
                    title: Text(
                      context.tr.faq, // Using existing faq translation
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      context.tr.findAnswers, // Using existing findAnswers translation
                      style: TextStyle(fontSize: 12, color: theme.hintColor),
                    ),
                    children: [
                      _FaqItem(question: context.tr.faqQ1, answer: context.tr.faqA1),
                      _FaqItem(question: context.tr.faqQ2, answer: context.tr.faqA2),
                      _FaqItem(question: context.tr.faqQ3, answer: context.tr.faqA3),
                      _FaqItem(question: context.tr.faqQ4, answer: context.tr.faqA4),
                      _FaqItem(question: context.tr.faqQ5, answer: context.tr.faqA5),
                      _FaqItem(question: context.tr.faqQ6, answer: context.tr.faqA6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr.wallet, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 15),

              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(currentUser: widget.currentUser),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFFDB2777),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.wallet,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.manageWallet,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr.payments, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 15),
              
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentHistoryScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        color: Color(0xFFDB2777),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr.paymentHistory,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.viewPaymentHistory,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),



        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionsPage(currentUser: widget.currentUser),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.subscriptions_outlined,
                      size: 24,
                      color: Color(0xFFDB2777),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      context.tr.subscriptions, 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: theme.textTheme.titleMedium?.color
                      )
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),



        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr.account, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
              const SizedBox(height: 15),
              // Become Creator Button
// 1. Wrap Become Creator
              if (!widget.currentUser.isArtist)
                InkWell(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreatorVerificationScreen(currentUser: widget.currentUser),
                      ),
                    );
                    // Refresh user data to reflect artist status change
                    final dbUser = await _dbHelper.getUserByUsername(widget.currentUser.username);
                    if (dbUser != null) {
                       widget.onSave(MockUser.fromJson(dbUser));
                       // Force UI rebuild if needed by calling setState locally if onSave doesn't trigger parent rebuild immediately (though it should)
                       setState(() {}); 
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDB2777).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDB2777).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_add_alt_1_outlined,
                          color: Color(0xFFDB2777),
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            context.tr.becomeCreator,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Color(0xFFDB2777)),
                      ],
                    ),
                  ),
                ),

              // 2. Update Logout
              InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: theme.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text(context.tr.logout, style: TextStyle(color: theme.textTheme.titleLarge?.color)),
                      content: Text(context.tr.confirmLogout, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(context.tr.cancel, style: TextStyle(color: theme.hintColor)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              // Update offline status
                              final updated = widget.currentUser.copyWith(isOnline: false);
                              await _dbHelper.insertUser(updated.toJson());
                            } catch (e) {
                              debugPrint("Error updating offline status: $e");
                            }
                            widget.onLogoutTap?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB2777),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(context.tr.logout),
                        ),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout,
                        color: Color(0xFFDB2777),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.logout,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr.signOut,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: theme.hintColor),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildLanguageSelector(ThemeData theme) {
      final currentLocale = Localizations.localeOf(context);
      
      // Define all languages with their native names and locale data
      final allLanguages = [
        {'code': 'en', 'name': 'English (US)', 'native': 'English', 'flag': '🇺🇸', 'locale': const Locale('en')},
        {'code': 'es', 'name': 'Spanish (Spain)', 'native': 'Español', 'flag': '🇪🇸', 'locale': const Locale('es')},
        {'code': 'fr', 'name': 'French (France)', 'native': 'Français', 'flag': '🇫🇷', 'locale': const Locale('fr')},
        {'code': 'de', 'name': 'German (Germany)', 'native': 'Deutsch', 'flag': '🇩🇪', 'locale': const Locale('de')},
        {'code': 'it', 'name': 'Italian (Italy)', 'native': 'Italiano', 'flag': '🇮🇹', 'locale': const Locale('it')},
        {'code': 'pt', 'name': 'Portuguese (Portugal)', 'native': 'Português', 'flag': '🇵🇹', 'locale': const Locale('pt')},
        {'code': 'ru', 'name': 'Russian (Russia)', 'native': 'Русский', 'flag': '🇷🇺', 'locale': const Locale('ru')},
        {'code': 'zh', 'name': 'Chinese (Simplified)', 'native': '简体中文', 'flag': '🇨🇳', 'locale': const Locale('zh')},
        {'code': 'zh_Hant', 'name': 'Chinese (Traditional)', 'native': '繁體中文', 'flag': '🇹🇼', 'locale': const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')},
        {'code': 'ja', 'name': 'Japanese (Japan)', 'native': '日本語', 'flag': '🇯🇵', 'locale': const Locale('ja')},
        {'code': 'ko', 'name': 'Korean (South Korea)', 'native': '한국어', 'flag': '🇰🇷', 'locale': const Locale('ko')},
        {'code': 'hi', 'name': 'Hindi (India)', 'native': 'हिन्दी', 'flag': '🇮🇳', 'locale': const Locale('hi')},
        {'code': 'ar', 'name': 'Arabic (Saudi Arabia)', 'native': 'العربية', 'flag': '🇸🇦', 'locale': const Locale('ar')},
        {'code': 'th', 'name': 'Thai (Thailand)', 'native': 'ไทย', 'flag': '🇹🇭', 'locale': const Locale('th')},
        {'code': 'vi', 'name': 'Vietnamese (Vietnam)', 'native': 'Tiếng Việt', 'flag': '🇻🇳', 'locale': const Locale('vi')},
        {'code': 'nl', 'name': 'Dutch (Netherlands)', 'native': 'Nederlands', 'flag': '🇳🇱', 'locale': const Locale('nl')},
        {'code': 'sv', 'name': 'Swedish (Sweden)', 'native': 'Svenska', 'flag': '🇸🇪', 'locale': const Locale('sv')},
        {'code': 'no', 'name': 'Norwegian (Norway)', 'native': 'Norsk', 'flag': '🇳🇴', 'locale': const Locale('no')},
        {'code': 'da', 'name': 'Danish (Denmark)', 'native': 'Dansk', 'flag': '🇩🇰', 'locale': const Locale('da')},
        {'code': 'fi', 'name': 'Finnish (Finland)', 'native': 'Suomi', 'flag': '🇫🇮', 'locale': const Locale('fi')},
        {'code': 'pl', 'name': 'Polish (Poland)', 'native': 'Polski', 'flag': '🇵🇱', 'locale': const Locale('pl')},
        {'code': 'cs', 'name': 'Czech (Czechia)', 'native': 'Čeština', 'flag': '🇨🇿', 'locale': const Locale('cs')},
        {'code': 'hu', 'name': 'Hungarian (Hungary)', 'native': 'Magyar', 'flag': '🇭🇺', 'locale': const Locale('hu')},
        {'code': 'ro', 'name': 'Romanian (Romania)', 'native': 'Română', 'flag': '🇷🇴', 'locale': const Locale('ro')},
        {'code': 'el', 'name': 'Greek (Greece)', 'native': 'Ελληνικά', 'flag': '🇬🇷', 'locale': const Locale('el')},
        {'code': 'tr', 'name': 'Turkish (Turkey)', 'native': 'Türkçe', 'flag': '🇹🇷', 'locale': const Locale('tr')},
        {'code': 'id', 'name': 'Indonesian (Indonesia)', 'native': 'Bahasa Indonesia', 'flag': '🇮🇩', 'locale': const Locale('id')},
        {'code': 'ms', 'name': 'Malay (Malaysia)', 'native': 'Bahasa Melayu', 'flag': '🇲🇾', 'locale': const Locale('ms')},
        {'code': 'fil', 'name': 'Filipino (Philippines)', 'native': 'Filipino', 'flag': '🇵🇭', 'locale': const Locale('fil')},
        {'code': 'sw', 'name': 'Swahili (East Africa)', 'native': 'Kiswahili', 'flag': '🇰🇪', 'locale': const Locale('sw')},
        {'code': 'ur', 'name': 'Urdu (Pakistan)', 'native': 'اردو', 'flag': '🇵🇰', 'locale': const Locale('ur')},
        {'code': 'bn', 'name': 'Bengali (Bangladesh)', 'native': 'বাংলা', 'flag': '🇧🇩', 'locale': const Locale('bn')},
      ];

      // Find current language mapping safely for display
      final currentLang = allLanguages.firstWhere(
        (lang) {
          final l = lang['locale'] as Locale;
          return l.languageCode == currentLocale.languageCode && 
                 l.scriptCode == currentLocale.scriptCode;
        },
        orElse: () => allLanguages[0],
      );

      return LayoutBuilder(
        builder: (context, constraints) {
          return MenuAnchor(
            alignmentOffset: const Offset(0, 0),
            style: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(theme.cardColor),
              elevation: const WidgetStatePropertyAll(8),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.3)),
              minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 0)),
              maximumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 400)),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            ),
            menuChildren: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  context.tr.selectLanguage,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...allLanguages.map((lang) {
                final l = lang['locale'] as Locale;
                final isSelected = l.languageCode == currentLocale.languageCode && 
                                 l.scriptCode == currentLocale.scriptCode;
                return MenuItemButton(
                  style: ButtonStyle(
                    backgroundColor: isSelected ? const WidgetStatePropertyAll(Color(0xFFDB2777)) : null,
                    minimumSize: WidgetStatePropertyAll(Size(constraints.maxWidth, 56)),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                    shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                  ),
                  onPressed: () => MyApp.of(context).setLocale(l),
                  child: Row(
                    children: [
                      Text(lang['flag'] as String, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              lang['name'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              lang['native'] as String,
                              style: TextStyle(
                                fontSize: 11, 
                                color: isSelected ? Colors.white70 : theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check, color: Colors.white, size: 18),
                    ],
                  ),
                );
              }),
            ],
            builder: (context, controller, child) {
              return InkWell(
                onTap: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Text(currentLang['flag'] as String, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLang['name'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge?.color,
                              ),
                            ),
                            Text(
                              currentLang['native'] as String,
                              style: TextStyle(fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        controller.isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: const Color(0xFFDB2777),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      );

  }


  Widget _buildThemeToggle(ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        widget.onThemeTap?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light ? const Color(0xFFF8F9FA) : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              color: const Color(0xFFDB2777),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDarkMode ? context.tr.darkMode : context.tr.lightMode,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: theme.textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDarkMode ? context.tr.currentlyDark : context.tr.currentlyLight,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              child: Switch(
                value: isDarkMode,
                onChanged: (value) {
                  widget.onThemeTap?.call();
                },
                activeThumbColor: const Color(0xFFDB2777),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDetailedNotificationRow(String title, bool value, Function(bool) onChanged, {bool isLast = false}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Label
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color, // Consistent text color
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              
              // Custom Styles Toggle/Checkbox
              GestureDetector(
                onTap: () => onChanged(!value),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: value ? const Color(0xFFDB2777) : Colors.transparent, 
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: value ? const Color(0xFFDB2777) : (theme.brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[400]!),
                          width: 1.5,
                        ),
                      ),
                      child: value 
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value ? context.tr.on : context.tr.off,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
      ],
    );
  }

  Future<void> _saveNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final username = widget.currentUser.username;
    await prefs.setBool('notifications_enabled_$username', _notificationsEnabled);
    await prefs.setBool('like_notifications_enabled_$username', _likeNotificationsEnabled);
    await prefs.setBool('comment_notifications_enabled_$username', _commentNotificationsEnabled);
    

    widget.onNotificationSettingsChanged?.call(
      _notificationsEnabled,
      _likeNotificationsEnabled,
      _commentNotificationsEnabled,
      _newSubNotifications,
      _tipNotifications,
      _messageNotifications,
      _expiringSubNotifications,
      _upcomingRenewalNotifications,
    );
  }


  

  Widget _buildSubscriptionHistory(ThemeData theme) {

    final subscriptions = <Map<String, dynamic>>[];
    
    if (subscriptions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light 
            ? const Color(0xFFF8F9FA) 
            : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 64,
              color: theme.hintColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.noSubscriptionsFound,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.subscriptionHistoryDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.light 
          ? const Color(0xFFF8F9FA) 
          : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          final username = subscription['username'] as String;
          final type = subscription['type'] as String;
          final date = subscription['date'] as DateTime?;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: index < subscriptions.length - 1 ? 1 : 0,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDB2777).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: Color(0xFFDB2777),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'subscribed' 
                          ? context.tr.subscribedTo(username)
                          : context.tr.subscribedToYou(username),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date != null 
                          ? "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
                          : context.tr.dateNotAvailable,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: type == 'subscribed' 
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                      : const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type == 'subscribed' ? context.tr.active : context.tr.subscriber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: type == 'subscribed' 
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF2196F3),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showContactSupportDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr.contactSupportTitle,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(context.tr.subjectRequired, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: subjectController,
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: context.tr.subject,
                      hintStyle: TextStyle(color: theme.hintColor, fontSize: 12),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFDB2777), width: 2.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.tr.messageRequired, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageController,
                    maxLines: 5,
                    style: TextStyle(fontSize: 13, color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      hintText: context.tr.message,
                      hintStyle: TextStyle(color: theme.hintColor, fontSize: 12),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFDB2777), width: 2.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(context.tr.cancel, style: const TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (subjectController.text.trim().isNotEmpty &&
                                messageController.text.trim().isNotEmpty) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr.supportRequestSubmitted),
                                  backgroundColor: Color(0xFFDB2777),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.tr.fillAllRequiredFields),
                                  backgroundColor: const Color(0xFFDB2777),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDB2777),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: Text(context.tr.submit, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Removed _buildSettingsFaqItem method as it is replaced by _FaqItem class
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3))),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          trailing: Icon(
            Icons.keyboard_arrow_down, 
            color: _isExpanded 
              ? const Color(0xFFDB2777) 
              : (theme.brightness == Brightness.dark ? Colors.white : Colors.black),
            size: 18
          ),
          title: Text(
            widget.question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(
              widget.answer,
              style: TextStyle(
                fontSize: 12,
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

