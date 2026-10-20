import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/xml_parser.dart';

enum SoapFailureType { notConfigured, timeout, transport, http, fault }

class SoapFailure {
  const SoapFailure({
    required this.type,
    required this.message,
    this.statusCode,
  });

  final SoapFailureType type;
  final String message;
  final int? statusCode;
}

class SoapClient {
  SoapClient({
    this.baseUrl = '',
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
  }) : _httpClient = httpClient ?? http.Client();

  String baseUrl;
  final http.Client _httpClient;
  final Duration timeout;
  SoapFailure? lastFailure;

  Future<String?> postRequest({
    required String methodName,
    required String envelope,
    String? requestUrl,
  }) async {
    lastFailure = null;
    final targetUrl = requestUrl ?? baseUrl;
    if (targetUrl.isEmpty) {
      lastFailure = const SoapFailure(
        type: SoapFailureType.notConfigured,
        message: 'Alamat layanan belum dikonfigurasi.',
      );
      return null;
    }
    try {
      final response = await _httpClient
          .post(
            Uri.parse(targetUrl),
            headers: {
              'Content-Type': 'text/xml; charset=utf-8',
              'SOAPAction': 'http://MMSD.org/$methodName',
            },
            body: utf8.encode(envelope),
          )
          .timeout(timeout);

      final faultMessage = XmlParser.parseSoapFault(response.body);
      if (faultMessage != null) {
        lastFailure = SoapFailure(
          type: SoapFailureType.fault,
          message: faultMessage,
          statusCode: response.statusCode,
        );
        return null;
      }
      if (response.statusCode == 200) return response.body;
      lastFailure = SoapFailure(
        type: SoapFailureType.http,
        message: 'Layanan mengembalikan HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
      return null;
    } on TimeoutException {
      lastFailure = const SoapFailure(
        type: SoapFailureType.timeout,
        message: 'Waktu koneksi ke layanan habis.',
      );
      return null;
    } catch (error) {
      lastFailure = SoapFailure(
        type: SoapFailureType.transport,
        message: 'Tidak dapat terhubung ke layanan: $error',
      );
      return null;
    }
  }
}
