import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/presence_model.dart';
import '../repositories/presence_repository.dart';


class ProfileViewModel extends ChangeNotifier {
  late final PresenceRepository _presenceRepository;

  bool _disposed = false;

  ProfileViewModel(Dio dio) {
    _presenceRepository = PresenceRepository(dio);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  PresenceModel? _presenceData;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _presenceData?.isOnline ?? false;

  Future<void> fetchPresence(String token) async {
    if (_disposed) return;
    _isLoading = true;
    _errorMessage = null;
    if (!_disposed) notifyListeners();

    try {
      _presenceData = await _presenceRepository.fetchPresence(token);
      if (_disposed) return;
    } catch (e) {
      if (_disposed) return;
      _errorMessage = e.toString();
      debugPrint('Presence error: $e');
    } finally {
      if (_disposed) return;
      _isLoading = false;
      notifyListeners();
    }
  }
}