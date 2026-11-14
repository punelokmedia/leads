import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/background_transformer.dart';

void main() {
  final transformer = AppBackgroundTransformer();
  Future<dynamic> decode(String text, ResponseType type, String mime) =>
      transformer.transformResponse(
        RequestOptions(path: '/test', responseType: type),
        ResponseBody.fromString(
          text,
          200,
          headers: {
            Headers.contentTypeHeader: [mime],
          },
        ),
      );

  test('small and large JSON payloads retain their values', () async {
    for (final count in [1, 20000]) {
      final data = {
        'rows': List.generate(count, (i) => {'id': i, 'name': 'Lead $i'}),
      };
      expect(
        await decode(jsonEncode(data), ResponseType.json, 'application/json'),
        data,
      );
    }
  });

  test(
    'text, binary and streamed responses retain their response types',
    () async {
      expect(
        await decode('not JSON', ResponseType.plain, 'text/plain'),
        'not JSON',
      );
      expect(
        await decode('not JSON', ResponseType.json, 'text/plain'),
        'not JSON',
      );
      expect(
        await decode('abc', ResponseType.bytes, 'application/octet-stream'),
        utf8.encode('abc'),
      );
      final body = ResponseBody.fromString('stream', 200);
      expect(
        await transformer.transformResponse(
          RequestOptions(path: '/test', responseType: ResponseType.stream),
          body,
        ),
        same(body),
      );
    },
  );
}
