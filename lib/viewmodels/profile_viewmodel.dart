import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/presence_model.dart';
import '../repositories/presence_repository.dart';

class ProfileViewModel extends ChangeNotifier {
  late final PresenceRepository _presenceRepository;

  ProfileViewModel(Dio dio) {
    _presenceRepository = PresenceRepository(dio);
  }

  PresenceModel? _presenceData;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _presenceData?.isOnline ?? false;

  Future<void> fetchPresence(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _presenceData = await _presenceRepository.fetchPresence(token);
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('Presence error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}