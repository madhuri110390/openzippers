import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

final presenceProvider = FutureProvider.autoDispose<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null || token.isEmpty) return false;

  try {
    final apiClient = ref.read(apiClientProvider); // match your actual provider name
    final presence = await apiClient.getPresence();
    return presence.isOnline;
  } catch (e) {
    return false;
  }
});