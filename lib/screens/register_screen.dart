import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/register_view_model.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  void _onFieldChanged(String field) {
    ref.read(registerViewModelProvider.notifier).clearError(field);
  }


  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  int? _selectedCountry;
  int? _selectedState;
  int? _selectedCity;
  String? _selectedGender;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _coverImagePath;
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isCover) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          if (isCover) {
            _coverImagePath = image.path;
          } else {
            _profileImagePath = image.path;
          }
        });
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }

  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(registerViewModelProvider.notifier).fetchCountries();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _profileNameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate() && _agreedToTerms) {
      final viewModel = ref.read(registerViewModelProvider.notifier);
      await viewModel.registerUser(
        name: _fullNameController.text,
        username: _profileNameController.text,
        mobileNumber: _mobileNumberController.text,
        countryId: _selectedCountry?.toString() ?? '1',
        stateId: _selectedState?.toString() ?? '1',
        cityId: _selectedCity?.toString() ?? '1',
        gender: _selectedGender?.toLowerCase() ?? 'other',
        email: _emailController.text,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        agree: 'true',
        avatar: _profileImagePath != null ? File(_profileImagePath!) : null,
        coverImage: _coverImagePath != null ? File(_coverImagePath!) : null,
        onSuccess: (token) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration success'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => LoginScreen(token: token)),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            _formKey.currentState!.validate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      );
    } else if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the Terms & Conditions.')),
      );
    }
  }

  InputDecoration _buildInputDecoration(String labelText, BuildContext context, {Widget? suffixIcon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.grey.shade300;

    return InputDecoration(
      hintText: labelText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDB2777), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      errorMaxLines: 3,
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildFieldColumn(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const Text(
              ' *',
              style: TextStyle(color: Color(0xFFDB2777), fontSize: 13, fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF151B2B) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallPhone = screenWidth < 600;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallPhone ? 16 : 24, 
            vertical: isSmallPhone ? 24 : 40,
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: EdgeInsets.all(isSmallPhone ? 24 : 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A2235) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? const Color(0xFF2A344A) : Colors.grey.shade200),
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join our community and start sharing',
                    style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                  // Cover Image & Avatar Stack
                  Container(
                    margin: const EdgeInsets.only(bottom: 54),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Cover Image Area
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: DottedBorder(
                            options: RoundedRectDottedBorderOptions(
                              color: const Color(0xFFDB2777),
                              strokeWidth: 1.5,
                              dashPattern: const [6, 4],
                              radius: const Radius.circular(12),
                            ),
                            child: Container(
                              width: double.infinity,
                              height: 210,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF151B2B).withValues(alpha: 0.5) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: _coverImagePath != null 
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_coverImagePath!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        'https://dev-openzippers.s3.us-east-1.amazonaws.com/users/covers/2026/01/1769768192_P11CdAEm0j.jpg',
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        // Avatar Circle placeholder
                        Positioned(
                          left: 32,
                          bottom: -40,
                          child: GestureDetector(
                            onTap: () => _pickImage(false),
                            child: Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFDB2777),
                                image: DecorationImage(
                                  image: _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!)) as ImageProvider
                                      : const NetworkImage('https://dev-openzippers.s3.us-east-1.amazonaws.com/users/avatars/2026/01/1769768192_jd1GNu8aH6.jpg'),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: const Color(0xFFDB2777),
                                  width: 4,
                                ),
                              ),
                              child: null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isLargeScreen = constraints.maxWidth > 800;
                      double fieldWidth3 = isLargeScreen ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                      double fieldWidth2 = isLargeScreen ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 24,
                        children: [
                          // Row 1: Full Name, Profile Name, Mobile Number
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'Full Name',
                              TextFormField(
                                controller: _fullNameController,
                                decoration: _buildInputDecoration('Enter your full name', context),
                                onChanged: (_) => _onFieldChanged('name'),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('name')) return registerState.backendErrors['name'];
                                  if (value == null || value.isEmpty) return 'Full Name is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'Profile Name',
                              TextFormField(
                                controller: _profileNameController,
                                decoration: _buildInputDecoration('Profile Name', context),
                                onChanged: (_) => _onFieldChanged('username'),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('username')) return registerState.backendErrors['username'];
                                  if (value == null || value.isEmpty) return 'Profile Name is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'Mobile Number',
                              TextFormField(
                                controller: _mobileNumberController,
                                keyboardType: TextInputType.phone,
                                decoration: _buildInputDecoration('Enter your mobile number', context),
                                onChanged: (_) => _onFieldChanged('mobile_number'),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('mobile_number')) return registerState.backendErrors['mobile_number'];
                                  if (value == null || value.isEmpty) return 'Mobile Number is required';
                                  return null;
                                },
                              ),
                            ),
                          ),

                          // Row 2: Country, State, City
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'Country',
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _selectedCountry,
                                icon: registerState.isFetchingLocations && registerState.countries.isEmpty
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDB2777)))
                                    : const Icon(Icons.unfold_more, size: 20),
                                decoration: _buildInputDecoration('Select your country', context),
                                items: registerState.countries.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: registerState.isFetchingLocations && registerState.countries.isEmpty ? null : (val) {
                                  setState(() {
                                    _selectedCountry = val;
                                    _selectedState = null;
                                    _selectedCity = null;
                                  });
                                  _onFieldChanged('country_id');
                                  if (val != null) {
                                    ref.read(registerViewModelProvider.notifier).fetchStates(val.toString());
                                  }
                                },
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('country_id')) return registerState.backendErrors['country_id'];
                                  if (value == null) return 'Country is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'State',
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _selectedState,
                                icon: registerState.isFetchingLocations && _selectedCountry != null && registerState.states.isEmpty
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDB2777)))
                                    : const Icon(Icons.unfold_more, size: 20),
                                decoration: _buildInputDecoration(_selectedCountry == null ? 'Select a country first' : 'Select your state', context),
                                items: registerState.states.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: _selectedCountry == null ? null : (val) {
                                  setState(() {
                                    _selectedState = val;
                                    _selectedCity = null;
                                  });
                                  _onFieldChanged('state_id');
                                  if (val != null) {
                                    ref.read(registerViewModelProvider.notifier).fetchCities(val.toString());
                                  }
                                },
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('state_id')) return registerState.backendErrors['state_id'];
                                  if (value == null) return 'State is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth3,
                            child: _buildFieldColumn(
                              'City',
                              DropdownButtonFormField<int>(
                                isExpanded: true,
                                initialValue: _selectedCity,
                                icon: registerState.isFetchingLocations && _selectedState != null && registerState.cities.isEmpty
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFDB2777)))
                                    : const Icon(Icons.unfold_more, size: 20),
                                decoration: _buildInputDecoration(_selectedState == null ? 'Select a state first' : 'Select your city', context),
                                items: registerState.cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: _selectedState == null ? null : (val) {
                                  setState(() => _selectedCity = val);
                                  _onFieldChanged('city_id');
                                },
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('city_id')) return registerState.backendErrors['city_id'];
                                  if (value == null) return 'City is required';
                                  return null;
                                },
                              ),
                            ),
                          ),

                          // Row 3: Gender, E-Mail
                          SizedBox(
                            width: fieldWidth2,
                            child: _buildFieldColumn(
                              'Gender',
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedGender,
                                icon: const Icon(Icons.unfold_more, size: 20),
                                decoration: _buildInputDecoration('Select your gender', context),
                                items: _genders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedGender = val);
                                  _onFieldChanged('gender');
                                },
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('gender')) return registerState.backendErrors['gender'];
                                  if (value == null) return 'Gender is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth2,
                            child: _buildFieldColumn(
                              'E-Mail Address',
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _buildInputDecoration('Enter your email address', context),
                                onChanged: (_) => _onFieldChanged('email'),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('email')) return registerState.backendErrors['email'];
                                  if (value == null || value.isEmpty) return 'Email is required';
                                  return null;
                                },
                              ),
                            ),
                          ),

                          // Row 4: Password, Confirm Password
                          SizedBox(
                            width: fieldWidth2,
                            child: _buildFieldColumn(
                              'Password',
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onChanged: (_) => _onFieldChanged('password'),
                                decoration: _buildInputDecoration(
                                  'Choose a strong password',
                                  context,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('password')) return registerState.backendErrors['password'];
                                  if (value == null || value.isEmpty) return 'Password is required';
                                  return null;
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            width: fieldWidth2,
                            child: _buildFieldColumn(
                              'Confirm Password',
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                onChanged: (_) => _onFieldChanged('password_confirmation'),
                                decoration: _buildInputDecoration(
                                  'Confirm your password',
                                  context,
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (registerState.backendErrors.containsKey('password_confirmation')) return registerState.backendErrors['password_confirmation'];
                                  if (value == null || value.isEmpty) return 'Please confirm your password';
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Terms & Conditions Checkbox
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                          activeColor: const Color(0xFFDB2777),
                          side: BorderSide(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: textColor, fontSize: 13),
                              children: const [
                                TextSpan(text: 'I agree to the '),
                                TextSpan(text: 'Terms & Conditions', style: TextStyle(color: Color(0xFFDB2777))),
                                TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFFDB2777))),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Bottom Action Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isSmall = constraints.maxWidth < 450;
                      
                      final loginButton = TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Already registered? Login here',
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14),
                        ),
                      );

                      final createButton = Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDB2777), Color(0xFF9333EA)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: registerState.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: registerState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                        ),
                      );

                      if (isSmall) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            createButton,
                            const SizedBox(height: 16),
                            loginButton,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          loginButton,
                          createButton,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
