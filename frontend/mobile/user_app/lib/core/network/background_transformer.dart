import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ignore: deprecated_member_use
class AppBackgroundTransformer extends DefaultTransformer {
  static const int _isolateThreshold = 50000; // ~50KB

  @override
  Future<dynamic> transformResponse(
      RequestOptions options, ResponseBody response) async {
    
    // Standard Dio transformation (returns a string or bytes)
    final transformed = await super.transformResponse(options, response);

    if (transformed is String && transformed.length > _isolateThreshold) {
      // Large payload → parse in background isolate to avoid UI jank
      return compute(_parseJson, transformed);
    }

    if (transformed is String) {
      // Small payload → parse synchronously (faster, no isolate overhead)
      return _parseJson(transformed);
    }

    return transformed;
  }
}

// Top-level function required for 'compute'
dynamic _parseJson(String text) {
  return jsonDecode(text);
}