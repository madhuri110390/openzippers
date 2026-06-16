// repositories/subscription_list_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/subscriptions_list_response.dart';

class SubscriptionListRepository {
  final Dio _dio;

  SubscriptionListRepository(this._dio);

  Future<SubscriptionListResponse> getSubscriptions() async {
    try {
      final response = await _dio.get(
        'https://openzippers.com/api/v1/settings/subscriptions',
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      debugPrint('SUBSCRIPTIONS STATUS: ${response.statusCode}');
      debugPrint('SUBSCRIPTIONS BODY: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> raw = response.data is Map
            ? Map<String, dynamic>.from(response.data)
            : {};

        // API wraps data under "subscriptions" key
        if (raw.containsKey('subscriptions')) {
          return SubscriptionListResponse(
            success: true,
            message: 'OK',
            data: SubscriptionListData.fromJson(
              raw['subscriptions'] as Map<String, dynamic>,
            ),
          );
        }
        // Fallback: try parsing root
        return SubscriptionListResponse.fromJson(raw);
      }

      throw Exception(
        'Failed to load subscriptions: ${response.statusCode}',
      );
    } on DioException catch (e) {
      debugPrint('SUBSCRIPTION REPO DIO ERROR: $e');
      rethrow;
    }
  }
}