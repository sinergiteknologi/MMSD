import 'package:flutter_test/flutter_test.dart';
import 'package:new_mmsd_apps/utils/menu_authority.dart';

void main() {
  test('authority matching uses exact transaction id', () {
    final authority = MenuAuthority.parse("'001','010'");

    expect(authority.canAccess('001'), isTrue);
    expect(authority.canAccess('010'), isTrue);
    expect(authority.canAccess('01'), isFalse);
    expect(authority.canAccess('101'), isFalse);
  });

  test('empty legacy authority allows all menus', () {
    expect(MenuAuthority.parse("''").canAccess('999'), isTrue);
  });
}
