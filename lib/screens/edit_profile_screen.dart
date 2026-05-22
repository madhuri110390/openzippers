import 'package:flutter/material.dart';
import 'package:dio/dio.dart' hide Headers;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../models/location_models.dart';
import '../models/mock_data.dart';
import '../helpers/translations.dart';
import '../providers/api_client_provider.dart';
import '../providers/edit_profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final MockUser currentUser;
  final Function(MockUser) onSave;
  final VoidCallback onBack;
  // Pass the real IDs from RegisterUser so we don't rely on name-matching
  final int? initialCountryId;
  final int? initialStateId;
  final int? initialCityId;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
    required this.onSave,
    required this.onBack,
    this.initialCountryId,
    this.initialStateId,
    this.initialCityId,
  });

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  // ── Controllers ───────────────────────────────────────────────────────────
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  // ── Location lists from API ───────────────────────────────────────────────
  List<Country> _countriesList = [];
  List<StateModel> _statesList = [];
  List<CityModel> _citiesList = [];

  // ── Selected IDs sent to API ──────────────────────────────────────────────
  int? _selectedCountryId;
  int? _selectedStateId;
  int? _selectedCityId;

  // ── Selected display names shown in dropdowns ─────────────────────────────
  String _selectedCountry = '';
  String _selectedState   = '';
  String _selectedCity    = '';
  String _selectedGender  = '';

  // ── Loading flags ─────────────────────────────────────────────────────────
  bool _isLoadingCountries = false;
  bool _isLoadingStates    = false;
  bool _isLoadingCities    = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];

  // ── Normalise for fuzzy matching ──────────────────────────────────────────
  String _norm(String s) =>
      s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  // ── Raw API helpers (handle both plain List and wrapped {"data":[...]}) ────
  static const _baseUrl = 'https://openzippers.com/api/v1';

  static const _headers = {
    'Accept': 'application/json',
    'openzippers-skip-browser-warning': 'true',
  };

  Future<List<Country>> _fetchCountries() async {
    final apiClient = ref.read(apiClientProvider);
    return await apiClient.getCountries();
  }

  Future<List<StateModel>> _fetchStates(int countryId) async {
    debugPrint('[Location] >>> states countryId=$countryId');
    final dio = ref.read(dioProvider);
    const url = 'https://openzippers.com/api/states';
    final resp = await dio.get(url,
        queryParameters: {'country_id': countryId},
        options: Options(headers: _headers));
    final raw = resp.data;
    final list = raw is List ? raw : (raw['data'] ?? raw['states'] ?? []);
    return (list as List).map((e) => StateModel.fromJson(Map<String,dynamic>.from(e))).toList();
  }

  Future<List<CityModel>> _fetchCities(int stateId) async {
    debugPrint('[Location] >>> cities stateId=$stateId');
    final dio = ref.read(dioProvider);
    const url = 'https://openzippers.com/api/cities';
    final resp = await dio.get(url,
        queryParameters: {'state_id': stateId},
        options: Options(headers: _headers));
    final raw = resp.data;
    final list = raw is List ? raw : (raw['data'] ?? raw['cities'] ?? []);
    return (list as List).map((e) => CityModel.fromJson(Map<String,dynamic>.from(e))).toList();
  }


  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _nameController            = TextEditingController(text: widget.currentUser.name);
    _usernameController        = TextEditingController(text: widget.currentUser.username);
    _bioController             = TextEditingController(text: widget.currentUser.bio);
    _phoneController           = TextEditingController(text: widget.currentUser.phone ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController     = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _selectedCountry = widget.currentUser.country;
    _selectedState   = widget.currentUser.state;
    _selectedCity    = widget.currentUser.city;
    _selectedGender  = widget.currentUser.gender;

    _loadCountries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── API: Load Countries ───────────────────────────────────────────────────
  Future<void> _loadCountries() async {
    // ✅ Use real IDs from RegisterUser (passed as widget params) — skip name matching
    final idFromWidget      = widget.initialCountryId;
    final stateIdFromWidget = widget.initialStateId;
    final cityIdFromWidget  = widget.initialCityId;
    final targetCountry     = _selectedCountry;
    final targetState       = _selectedState;
    final targetCity        = _selectedCity;

    setState(() => _isLoadingCountries = true);
    try {
      final result = await _fetchCountries();

      if (!mounted) return;

      debugPrint('[Location] Countries (${result.length}): ${result.map((c) => "${c.id}:${c.name}").join(", ")}');
      debugPrint('[Location] initialCountryId=$idFromWidget  name="$targetCountry"');

      int? matchedId;
      String? matchedName;

      // PRIMARY: match by real ID — 100% reliable
      if (idFromWidget != null) {
        final m = result.where((c) => c.id == idFromWidget);
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ Country by ID → $matchedId $matchedName'
            : '[Location] ⚠️ ID $idFromWidget not in list');
      }

      // FALLBACK: match by name
      if (matchedId == null) {
        final m = result.where((c) => _norm(c.name) == _norm(targetCountry));
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ Country by name → $matchedId $matchedName'
            : '[Location] ❌ Country not matched at all');
      }

      setState(() {
        _countriesList      = result;
        _isLoadingCountries = false;
        if (matchedId != null) {
          _selectedCountryId = matchedId;
          _selectedCountry   = matchedName!;
        }
      });

      if (matchedId != null) {
        _loadStates(
          matchedId,
          targetStateId: stateIdFromWidget,
          targetState:   targetState,
          targetCityId:  cityIdFromWidget,
          targetCity:    targetCity,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCountries = false);
      debugPrint('[Location] Error loading countries: $e');
    }
  }


  // ── API: Load States ──────────────────────────────────────────────────────
  // targetState / targetCity passed explicitly — never rely on this._ during async
  Future<void> _loadStates(
      int countryId, {
        int? targetStateId,
        String targetState = '',
        int? targetCityId,
        String targetCity  = '',
      }) async {
    setState(() {
      _isLoadingStates = true;
      _statesList      = [];
      _citiesList      = [];
      _selectedStateId = null;
      _selectedCityId  = null;
      _selectedState   = '';
      _selectedCity    = '';
    });

    try {
      final result = await _fetchStates(countryId);

      if (!mounted) return;

      debugPrint('[Location] States (${result.length}): ${result.map((s) => "${s.id}:${s.name}").join(", ")}');
      debugPrint('[Location] targetStateId=$targetStateId  name="$targetState"');

      int? matchedId;
      String? matchedName;

      // PRIMARY: match by real ID
      if (targetStateId != null) {
        final m = result.where((s) => s.id == targetStateId);
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ State by ID → $matchedId $matchedName'
            : '[Location] ⚠️ State ID $targetStateId not in list');
      }

      // FALLBACK: match by name
      if (matchedId == null && targetState.isNotEmpty) {
        final m = result.where((s) => _norm(s.name) == _norm(targetState));
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ State by name → $matchedId $matchedName'
            : '[Location] ❌ State not matched');
      }

      setState(() {
        _statesList      = result;
        _isLoadingStates = false;
        if (matchedId != null) {
          _selectedStateId = matchedId;
          _selectedState   = matchedName!;
        }
      });

      if (matchedId != null) {
        _loadCities(matchedId, targetCityId: targetCityId, targetCity: targetCity);
      }
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _isLoadingStates = false);
      debugPrint('[Location] ❌ STATES ERROR: $e');
      if (e is DioException) {
        debugPrint('[Location] DioException type: ${e.type}');
        debugPrint('[Location] DioException response: ${e.response?.data}');
        debugPrint('[Location] DioException statusCode: ${e.response?.statusCode}');
        debugPrint('[Location] DioException requestUrl: ${e.requestOptions.uri}');
      }
      // Show visible error so user knows something went wrong
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load states: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _loadCities(
      int stateId, {
        int? targetCityId,
        String targetCity = '',
      }) async {
    setState(() {
      _isLoadingCities = true;
      _citiesList      = [];
      _selectedCityId  = null;
      _selectedCity    = '';
    });

    try {
      final result = await _fetchCities(stateId);

      if (!mounted) return;

      debugPrint('[Location] Cities (${result.length}): ${result.map((c) => "${c.id}:${c.name}").join(", ")}');
      debugPrint('[Location] targetCityId=$targetCityId  name="$targetCity"');

      int? matchedId;
      String? matchedName;

      // PRIMARY: match by real ID
      if (targetCityId != null) {
        final m = result.where((c) => c.id == targetCityId);
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ City by ID → $matchedId $matchedName'
            : '[Location] ⚠️ City ID $targetCityId not in list');
      }

      // FALLBACK: match by name
      if (matchedId == null && targetCity.isNotEmpty) {
        final m = result.where((c) => _norm(c.name) == _norm(targetCity));
        if (m.isNotEmpty) { matchedId = m.first.id; matchedName = m.first.name; }
        debugPrint(matchedId != null
            ? '[Location] ✅ City by name → $matchedId $matchedName'
            : '[Location] ❌ City not matched');
      }

      setState(() {
        _citiesList      = result;
        _isLoadingCities = false;
        if (matchedId != null) {
          _selectedCityId = matchedId;
          _selectedCity   = matchedName!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
      debugPrint('[Location] Error loading cities: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final editState = ref.watch(editProfileProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          color: theme.textTheme.bodyLarge?.color,
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
            const SizedBox(height: 20),

            // Full Name
            _buildTextField(theme,
                controller: _nameController,
                label: context.tr.legalFullName,
                hint: context.tr.enterYourFullName),
            const SizedBox(height: 16),

            // Username
            _buildTextField(theme,
                controller: _usernameController,
                label: context.tr.username,
                hint: context.tr.enterYourUsername),
            const SizedBox(height: 16),

            // Phone
            _buildTextField(theme,
                controller: _phoneController,
                label: context.tr.phoneNumber,
                hint: context.tr.phoneNumber,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 16),

            // ── Country Dropdown ──────────────────────────────────────────
            _isLoadingCountries
                ? _buildLoadingDropdown(theme, context.tr.country)
                : _buildDropdownField(
              theme,
              label: context.tr.country,
              value: _selectedCountry.isNotEmpty ? _selectedCountry : null,
              items: _countriesList.map((c) => c.name).toList(),
              onChanged: (value) {
                final selected =
                _countriesList.firstWhere((c) => c.name == value);
                setState(() {
                  _selectedCountry   = value;
                  _selectedCountryId = selected.id;
                  _selectedState     = '';
                  _selectedCity      = '';
                  _selectedStateId   = null;
                  _selectedCityId    = null;
                });
                // No auto-match when user manually picks country
                _loadStates(selected.id);
              },
            ),

            // ── State Dropdown ────────────────────────────────────────────
            _isLoadingStates
                ? _buildLoadingDropdown(theme, context.tr.state)
                : _buildDropdownField(
              theme,
              label: context.tr.state,
              value: _selectedState.isNotEmpty &&
                  _statesList.any((s) => s.name == _selectedState)
                  ? _selectedState
                  : null,
              items: _statesList.map((s) => s.name).toList(),
              enabled: _statesList.isNotEmpty,
              onChanged: (value) {
                final selected =
                _statesList.firstWhere((s) => s.name == value);
                setState(() {
                  _selectedState   = value;
                  _selectedStateId = selected.id;
                  _selectedCity    = '';
                  _selectedCityId  = null;
                });
                // No auto-match when user manually picks state
                _loadCities(selected.id);
              },
            ),

            // ── City Dropdown ─────────────────────────────────────────────
            _isLoadingCities
                ? _buildLoadingDropdown(theme, context.tr.city)
                : _buildDropdownField(
              theme,
              label: context.tr.city,
              value: _selectedCity.isNotEmpty &&
                  _citiesList.any((c) => c.name == _selectedCity)
                  ? _selectedCity
                  : null,
              items: _citiesList.map((c) => c.name).toList(),
              enabled: _citiesList.isNotEmpty,
              onChanged: (value) {
                final selected =
                _citiesList.firstWhere((c) => c.name == value);
                setState(() {
                  _selectedCity   = value;
                  _selectedCityId = selected.id;
                });
              },
            ),

            // ── Gender Dropdown ───────────────────────────────────────────
            _buildDropdownField(
              theme,
              label: context.tr.gender,
              value: _selectedGender.isNotEmpty ? _selectedGender : null,
              items: _genders,
              onChanged: (value) => setState(() => _selectedGender = value),
            ),

            // Bio
            _buildTextField(theme,
                controller: _bioController,
                label: context.tr.bio,
                hint: context.tr.tellUsAboutYourself,
                maxLines: 3),
            const SizedBox(height: 30),

            // ── Save Changes Button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_selectedCountryId == null ||
                      _selectedStateId == null ||
                      _selectedCityId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                        Text('Please select your country, state and city'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await ref
                      .read(editProfileProvider.notifier)
                      .updateProfile(
                    name:         _nameController.text.trim(),
                    username:     _usernameController.text.trim(),
                    mobileNumber: _phoneController.text.trim(),
                    countryId:    _selectedCountryId!,
                    stateId:      _selectedStateId!,
                    cityId:       _selectedCityId!,
                    gender:       _selectedGender,
                    bio:          _bioController.text.trim(),
                  );

                  final state = ref.read(editProfileProvider);

                  if (!context.mounted) return;

                  if (state.isSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }

                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB2777),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: editState.isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ── Change Password Section ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light
                    ? Colors.white
                    : theme.colorScheme.surfaceContainerHighest
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.changePassword,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPasswordField(theme,
                      controller: _currentPasswordController,
                      label: context.tr.currentPassword,
                      hint: context.tr.enterCurrentPassword),
                  const SizedBox(height: 16),
                  _buildPasswordField(theme,
                      controller: _newPasswordController,
                      label: context.tr.newPassword,
                      hint: context.tr.enterNewPassword),
                  const SizedBox(height: 16),
                  _buildPasswordField(theme,
                      controller: _confirmPasswordController,
                      label: context.tr.confirmNewPassword,
                      hint: context.tr.confirmNewPasswordHint),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final currentPass = _currentPasswordController.text;
                        final newPass     = _newPasswordController.text;
                        final confirmPass = _confirmPasswordController.text;

                        if (currentPass.isEmpty ||
                            newPass.isEmpty ||
                            confirmPass.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.tr.fillAllPasswordFields),
                          ));
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(context.tr.passwordsDoNotMatch),
                          ));
                          return;
                        }

                        try {
                          final authRepo = ref.read(authRepositoryProvider);
                          final response = await authRepo.changePasswordUser(
                            currentPassword:      currentPass,
                            password:             newPass,
                            passwordConfirmation: confirmPass,
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message ??
                                  context.tr.passwordSetSuccessfully),
                              backgroundColor: response.success == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );

                          if (response.success == true) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Something went wrong. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDB2777),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        context.tr.savePassword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Loading Placeholder ───────────────────────────────────────────────────
  Widget _buildLoadingDropdown(ThemeData theme, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            )),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.light
                ? const Color(0xFFF8F9FA)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(width: 12),
              Text('Loading $label...',
                  style: TextStyle(color: theme.hintColor, fontSize: 15)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Text Field ────────────────────────────────────────────────────────────
  Widget _buildTextField(
      ThemeData theme, {
        required TextEditingController controller,
        required String label,
        required String hint,
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.hintColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
              const BorderSide(color: Color(0xFFDB2777), width: 2.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: theme.brightness == Brightness.light
                ? const Color(0xFFF8F9FA)
                : theme.colorScheme.surfaceContainerHighest,
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
        ),
      ],
    );
  }

  // ── Password Field ────────────────────────────────────────────────────────
  Widget _buildPasswordField(
      ThemeData theme, {
        required TextEditingController controller,
        required String label,
        required String hint,
      }) {
    bool obscureText = true;
    return StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.textTheme.bodyMedium?.color,
                )),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              obscureText: obscureText,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.hintColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: theme.hintColor,
                  ),
                  onPressed: () => setLocal(() => obscureText = !obscureText),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                  const BorderSide(color: Color(0xFFDB2777), width: 2.5),
                ),
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                filled: true,
                fillColor: theme.brightness == Brightness.light
                    ? const Color(0xFFF8F9FA)
                    : theme.colorScheme.surfaceContainerHighest,
              ),
              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
            ),
          ],
        );
      },
    );
  }

  // ── Dropdown Field ────────────────────────────────────────────────────────
  Widget _buildDropdownField(
      ThemeData theme, {
        required String label,
        String? value,
        required List<String> items,
        required Function(String) onChanged,
        bool enabled = true,
        Map<String, String>? itemIcons,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            )),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return MenuAnchor(
              alignmentOffset: const Offset(0, 0),
              style: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(theme.cardColor),
                elevation: const WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                )),
                surfaceTintColor:
                const WidgetStatePropertyAll(Colors.transparent),
                shadowColor:
                WidgetStatePropertyAll(Colors.black.withOpacity(0.3)),
                fixedSize:
                WidgetStatePropertyAll(Size(constraints.maxWidth, 400)),
                maximumSize:
                WidgetStatePropertyAll(Size(constraints.maxWidth, 400)),
              ),
              menuChildren: items.isEmpty
                  ? [
                MenuItemButton(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      context.tr.noOptionsAvailable,
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ),
                ),
              ]
                  : items.map((item) {
                final isSelected = item == value;
                return MenuItemButton(
                  style: ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(
                        Size(constraints.maxWidth, 48)),
                  ),
                  onPressed: () => onChanged(item),
                  child: Container(
                    width: constraints.maxWidth - 24,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        if (itemIcons != null &&
                            itemIcons.containsKey(item)) ...[
                          Text(itemIcons[item]!,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(item,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFFDB2777)
                                    : theme.textTheme.bodyLarge?.color,
                              )),
                        ),
                        if (isSelected)
                          const Icon(Icons.check,
                              color: Color(0xFFDB2777), size: 16),
                      ],
                    ),
                  ),
                );
              }).toList(),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: enabled && items.isNotEmpty
                      ? () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: enabled
                          ? (theme.brightness == Brightness.light
                          ? const Color(0xFFF8F9FA)
                          : theme.colorScheme.surfaceContainerHighest)
                          : theme.disabledColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        if (itemIcons != null &&
                            value != null &&
                            itemIcons.containsKey(value)) ...[
                          Text(itemIcons[value]!,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            value ??
                                (items.isEmpty
                                    ? 'No $label available'
                                    : 'Select $label'),
                            style: TextStyle(
                              color: value != null
                                  ? theme.textTheme.bodyLarge?.color
                                  : theme.hintColor,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.keyboard_arrow_down,
                            color: theme.hintColor, size: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}