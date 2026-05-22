import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openzippers/screens/reset_password.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;
}

class MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;
  ThemeMode _themeMode = ThemeMode.light;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _initDeepLinks(); // ← start listening for deep links
  }

  // ── Deep link handler ───────────────────────────────────────────────────────
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle link if app was opened cold (killed state) by tapping the link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle link if app was already running (background/foreground)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Matches: https://openzippers.com/reset-password?token=xxx&email=yyy
    if (uri.path.contains('reset-password')) {
      final token = uri.queryParameters['token'] ?? '';
      final email = uri.queryParameters['email'] ?? '';

      if (token.isNotEmpty && email.isNotEmpty) {
        // Navigate to ResetPasswordScreen with token + email from the link
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              email: email,
              token: token,
            ),
          ),
        );
      }
    }
  }

  // ── Config ──────────────────────────────────────────────────────────────────
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    final langCode = prefs.getString('language_code');
    final scriptCode = prefs.getString('script_code');
    final countryCode = prefs.getString('country_code');
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      if (langCode != null) {
        _locale = Locale.fromSubtags(
          languageCode: langCode,
          scriptCode: scriptCode,
          countryCode: countryCode,
        );
      }
    });
  }

  void setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    if (locale.scriptCode != null) {
      await prefs.setString('script_code', locale.scriptCode!);
    } else {
      await prefs.remove('script_code');
    }
    if (locale.countryCode != null) {
      await prefs.setString('country_code', locale.countryCode!);
    } else {
      await prefs.remove('country_code');
    }
  }

  void toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    await prefs.setBool('isDarkMode', _themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(_locale?.languageCode ?? 'en'),
      navigatorKey: _navigatorKey, // ← required for deep link navigation
      title: 'OpenZippers',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      // LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDB2777),
          surface: const Color(0xFFF5F7FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFDB2777),
          selectionColor: Color(0x33DB2777),
          selectionHandleColor: Color(0xFFDB2777),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2),
          ),
        ),
      ),
      // DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF0F172A),
          surface: const Color(0xFF0F172A),
          surfaceContainer: const Color(0xFF0F172A),
          surfaceContainerHigh: const Color(0xFF0F172A),
          surfaceContainerHighest: const Color(0xFF1E293B),
          surfaceContainerLow: const Color(0xFF0F172A),
          surfaceContainerLowest: const Color(0xFF0F172A),
          onSurface: Colors.white,
          onSurfaceVariant: Colors.white70,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        canvasColor: const Color(0xFF0F172A),
        dividerColor: const Color(0xFF1E293B),
        shadowColor: Colors.black,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFDB2777),
          selectionColor: Color(0x33DB2777),
          selectionHandleColor: Color(0xFFDB2777),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F172A),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2),
          ),
        ),
        dialogTheme:
        const DialogThemeData(backgroundColor: Color(0xFF1E293B)),
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        double scale =
        screenWidth < 360 ? 0.95 : (screenWidth > 400 ? 1.05 : 1.0);
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}