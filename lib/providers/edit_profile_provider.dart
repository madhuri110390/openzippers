import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/edit_profile_state.dart';
import '../repositories/auth_repository.dart';
import 'auth_provider.dart';


final editProfileProvider =
StateNotifierProvider<EditProfileNotifier, EditProfileState>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return EditProfileNotifier(repo);
});

class EditProfileNotifier extends StateNotifier<EditProfileState> {
  final AuthRepository repository;

  EditProfileNotifier(this.repository)
      : super(const EditProfileState());

  Future<void> updateProfile({
    required String name,
    required String username,
    required String mobileNumber,
    required int countryId,
    required int stateId,
    required int cityId,
    required String gender,
    String? bio,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await repository.updateProfile(
        name: name,
        username: username,
        mobileNumber: mobileNumber,
        countryId: countryId,
        stateId: stateId,
        cityId: cityId,
        gender: gender,
        bio: bio,
      );

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}