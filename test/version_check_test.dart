import 'package:flutter_test/flutter_test.dart';
import 'package:new_mmsd_apps/models/version_check.dart';

void main() {
  test('mandatory upgrade only blocks older builds', () {
    final check = VersionCheck.parse('118/10.17/True', currentVersionCode: 117);

    expect(check, isNotNull);
    expect(check!.isMandatory, isTrue);
    expect(check.isUpgradeRequired, isTrue);
  });

  test('optional and malformed versions do not block startup', () {
    expect(
      VersionCheck.parse(
        '118/10.17/False',
        currentVersionCode: 117,
      )?.isUpgradeRequired,
      isFalse,
    );
    expect(VersionCheck.parse('invalid', currentVersionCode: 117), isNull);
  });
}
