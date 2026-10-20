import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:new_mmsd_apps/services/soap_client.dart';

void main() {
  test('captures SOAP fault message from a successful HTTP response', () async {
    final httpClient = MockClient((_) async {
      return http.Response(
        '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'
        '<soap:Body><soap:Fault><faultcode>soap:Server</faultcode>'
        '<faultstring>Request failed</faultstring><detail><Error>'
        '<ErrorMessage>Business rule failed</ErrorMessage>'
        '</Error></detail></soap:Fault></soap:Body></soap:Envelope>',
        200,
      );
    });
    final client = SoapClient(
      baseUrl: 'http://localhost/service.asmx',
      httpClient: httpClient,
    );

    final body = await client.postRequest(
      methodName: 'Login',
      envelope: '<xml />',
    );

    expect(body, isNull);
    expect(client.lastFailure?.type, SoapFailureType.fault);
    expect(client.lastFailure?.message, 'Business rule failed');
  });

  test('keeps non-200 HTTP status as a typed failure', () async {
    final client = SoapClient(
      baseUrl: 'http://localhost/service.asmx',
      httpClient: MockClient((_) async => http.Response('unavailable', 503)),
    );

    await client.postRequest(methodName: 'Versi', envelope: '<xml />');

    expect(client.lastFailure?.type, SoapFailureType.http);
    expect(client.lastFailure?.statusCode, 503);
  });
}
