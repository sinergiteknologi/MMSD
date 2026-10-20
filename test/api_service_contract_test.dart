import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_mmsd_apps/services/api_service.dart';
import 'package:new_mmsd_apps/services/rest_client.dart';
import 'package:new_mmsd_apps/utils/app_config.dart';

void main() {
  test('bootstrap request uses Node API URL', () async {
    late http.Request captured;
    final api = ApiService(
      client: RestClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"Versi":{"Versi":"117"}}', 200);
        }),
      ),
    )..configure(server: 'business.example', bisnis: 'MM');

    await api.getVersi();

    expect(
      captured.url,
      Uri.parse(
        '${AppConfig.defaultServiceUrl()}/ApiNewMMSDMobile/api/mobile/Versi',
      ),
    );
    expect(captured.headers['Content-Type'], contains('application/json'));
  });

  test('login JSON preserves parameter names', () async {
    late http.Request captured;
    final api = ApiService(
      client: RestClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"Login":{"KodeCabang":"001"}}', 200);
        }),
      ),
    )..configure(server: 'business.example', bisnis: 'A&B');

    await api.login(sCabang: '0001', sUser: 'a<b', sPwd: 'x&y');

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['sBisnis'], 'A&B');
    expect(body['sCabang'], '0001');
    expect(body['sUser'], 'a<b');
    expect(body['sPwd'], 'x&y');
  });

  test('fleet report uses the legacy field names', () async {
    late http.Request captured;
    final api = ApiService(
      client: RestClient(
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response('{"DataPref":{"Pref1":""}}', 200);
        }),
      ),
    )..configure(server: 'business.example', bisnis: 'MM');

    await api.getReportFleetDetail({
      'prmSP': 'Fleet DetailSales',
      'prmBusCode': '001',
      'prmUser': 'SALES',
      'prmFC1': '',
      'prmFC2': '',
      'prmDate1': '09/01/2026',
      'prmDate2': '09/30/2026',
      'prmUserStatus': 'SPV',
      'prmStatus': '',
    });

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['prmBusCode'], '001');
    expect(body['prmFC1'], '');
    expect(body.containsKey('prmBranchCode'), isFalse);
  });
}
