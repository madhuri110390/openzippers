import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_response.dart';
import '../network/api_client.dart';       // adjust path
import '../providers/api_client_provider.dart';
 // wherever apiClientProvider lives

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
class ReportState {
  final bool isLoading;
  final bool? success;
  final String? message;

  const ReportState({
    this.isLoading = false,
    this.success,
    this.message,
  });

  ReportState copyWith({
    bool? isLoading,
    bool? success,
    String? message,
  }) =>
      ReportState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        message: message ?? this.message,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────
class ReportNotifier extends StateNotifier<ReportState> {
  ReportNotifier(this._api) : super(const ReportState());

  final ApiClient _api;

  Future<ReportResponse?> reportPost({
    required int postId,
    required String reason,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, message: null, success: null);

    try {
      // Retrofit returns ReportResponse directly — no casting needed
      final response = await _api.reportPost({
        'post_id': postId,
        'reason': reason,
        'description': description,
      });

      state = state.copyWith(
        isLoading: false,
        success: response.status,
        message: response.message,
      );

      return response;

    } on DioException catch (e) {
      final serverMsg = _parseServerMessage(e);
      state = state.copyWith(
        isLoading: false,
        success: false,
        message: serverMsg,
      );
      return ReportResponse(status: false, message: serverMsg);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        success: false,
        message: 'Something went wrong. Please try again.',
      );
      return ReportResponse(
        status: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  String _parseServerMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ??
            data['error']?.toString() ??
            'Report failed';
      }
      if (data is String && data.isNotEmpty) return data;
    } catch (_) {}
    return 'Report failed';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final reportProvider =
StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final api = ref.watch(apiClientProvider);
  return ReportNotifier(api);
});