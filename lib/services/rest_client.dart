import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum RestFailureType { notConfigured, timeout, transport, http, fault }

class RestFailure {
  const RestFailure({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final RestFailureType type;
  final String message;
  final int? statusCode;
}

class RestClient {
  RestClient({
    this.baseUrl = '',
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  String baseUrl;
  final http.Client _httpClient;
  final Duration timeout;
  RestFailure? lastFailure;

  Future<String?> postJson({
    required String methodName,
    Map<String, String>? body,
    String? requestUrl,
  }) async {
    lastFailure = null;
    final root = requestUrl ?? baseUrl;
    if (root.isEmpty) {
      lastFailure = const RestFailure(
        type: RestFailureType.notConfigured,
        message: 'Alamat layanan belum dikonfigurasi.',
      );
      return null;
    }
    final uri = Uri.parse(
      root.endsWith('/')
          ? '${root}ApiNewMMSDMobile/api/mobile/$methodName'
          : '$root/ApiNewMMSDMobile/api/mobile/$methodName',
    );
    print(
      '[API] domain=${uri.host}:${uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80)} '
      'hit=${uri.toString()} method=$methodName',
    );
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(body ?? const {}),
          )
          .timeout(timeout);
      print('[API] response ${response.statusCode} hit=${uri.toString()}');
      if (response.statusCode != 200) {
        lastFailure = RestFailure(
          type: RestFailureType.http,
          message: 'Layanan mengembalikan HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] != null) {
        lastFailure = RestFailure(
          type: RestFailureType.fault,
          message: decoded['error'].toString(),
          statusCode: response.statusCode,
        );
        return null;
      }
      return response.body;
    } on TimeoutException {
      print('[API] timeout hit=${uri.toString()}');
      lastFailure = const RestFailure(
        type: RestFailureType.timeout,
        message: 'Waktu koneksi ke layanan habis.',
      );
      return null;
    } catch (error) {
      print('[API] error hit=${uri.toString()} — $error');
      lastFailure = RestFailure(
        type: RestFailureType.transport,
        message: 'Tidak dapat terhubung ke layanan: $error',
      );
      return null;
    }
  }
}
