import 'package:shared_preferences/shared_preferences.dart';

class PrefService {
  static const String keyIsLogin = 'ISLOGIN';
  static const String keyUsername = 'USER_USERNAME';
  static const String keyPassword = 'USER_PASSWORD';
  static const String keyBusCode = 'USER_BUSCODE';
  static const String keyBusName = 'USER_BUSNAME';
  static const String keySalesCode = 'USER_SALESCODE';
  static const String keySalesName = 'USER_SALESNAME';
  static const String keyAuthority = 'USER_AUTHORITY';
  static const String keyUserGroup = 'USER_USERGROUP';
  static const String keyBusAut = 'USER_BUSAUT';
  static const String keyBusNameAut = 'USER_BUSNAMEAUT';
  static const String keyUserStatus = 'USER_STATUS';
  static const String keyMainAut = 'USER_MAINAUT';
  static const String keyServer = 'APP_SERVER';
  static const String keyBisnis = 'APP_BISNIS';
  static const String keyFilterStatus = 'APP_FILTER_STATUS';
  static const String keyHisIdNo = 'APP_HIS_IDNO';
  static const String keyHisHistoryId = 'APP_HIS_HISTORYID';
  static const String keyHisStatus = 'APP_HIS_STATUS';
  static const String keyHisName = 'APP_HIS_NAME';
  static const String keyHisTlp = 'APP_HIS_TLP';
  static const String keyHisSalesName = 'APP_HIS_SALESNAME';
  static const String keySpkNo = 'APP_SPK_NO';
  static const String keyFormName = 'FORM_NAME';
  static const String keyFormPosition = 'FORM_POSITION';
  static const String keyRootForm = 'APP_ROOT_FORM';
  static const String keyFilterDate1 = 'APP_FILTER_DATE1';
  static const String keyFilterDate2 = 'APP_FILTER_DATE2';
  static const String keyPersonalCompany = 'PERSONALCOMPANY';
  static const String keyCustomerCode = 'CUSTOMERCODE';
  static const String keyFromUnit = 'FROMUNIT';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  Future<String> getString(String key, [String fallback = '']) async {
    final prefs = await _prefs;
    return prefs.getString(key) ?? fallback;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(key, value);
  }

  Future<bool> getBool(String key, [bool fallback = false]) async {
    final prefs = await _prefs;
    return prefs.getBool(key) ?? fallback;
  }

  Future<void> saveLoginStatus(bool status) async {
    await setString(keyIsLogin, status ? 'YES' : 'NO');
  }

  Future<bool> getLoginStatus() async {
    final value = await getString(keyIsLogin);
    return value == 'YES' || value.toLowerCase() == 'true';
  }

  Future<void> saveServer(String server, String bisnis) async {
    await setString(keyServer, server);
    await setString(keyBisnis, bisnis);
  }

  Future<void> saveLoginData({
    required String username,
    required String password,
    required String busCode,
    required String busName,
    required String salesCode,
    required String salesName,
    required String busAut,
    required String authority,
    required String userGroup,
    required String userStatus,
    required String busNameAut,
  }) async {
    await saveLoginStatus(true);
    await setString(keyUsername, username);
    await setString(keyPassword, password);
    await setString(keyBusCode, busCode);
    await setString(keyBusName, busName);
    await setString(keySalesCode, salesCode);
    await setString(keySalesName, salesName);
    await setString(keyBusAut, busAut);
    await setString(keyAuthority, authority);
    await setString(keyUserGroup, userGroup);
    await setString(keyUserStatus, userStatus);
    await setString(keyBusNameAut, busNameAut);
    await setMainMenuAuthority(authority);
  }

  Future<void> setMainMenuAuthority(String authority) async {
    if (authority.isEmpty || authority == "''") {
      await setString(keyMainAut, "''");
      return;
    }
    final menus = <String>[];
    for (final raw in authority.split('|')) {
      final value = raw.replaceAll("'", '');
      if (value.length >= 5 && value.substring(3, 5) == '00') {
        menus.add("'${value.substring(0, 3)}'");
      }
    }
    await setString(keyMainAut, menus.isEmpty ? "''" : menus.join(','));
  }

  Future<void> saveDataHistorySelected({
    required String idNo,
    required String historyId,
    required String status,
    required String name,
    required String tlp,
    required String salesName,
    String spkNo = '',
  }) async {
    await setString(keyHisIdNo, idNo);
    await setString(keyHisHistoryId, historyId);
    await setString(keyHisStatus, status);
    await setString(keyHisName, name);
    await setString(keyHisTlp, tlp);
    await setString(keyHisSalesName, salesName);
    await setString(keySpkNo, spkNo);
  }

  Future<void> saveStatusFilter(String status) async {
    await setString(keyFilterStatus, status);
  }

  Future<void> saveFiltering(String date1, String date2) async {
    await setString(keyFilterDate1, date1);
    await setString(keyFilterDate2, date2);
  }

  Future<void> saveFormName(String name, String position) async {
    await setString(keyFormName, name);
    await setString(keyFormPosition, position);
  }

  Future<void> saveRootMenu(String rootForm) async {
    await setString(keyRootForm, rootForm);
  }

  Future<void> saveFromUnit(bool fromUnit) async {
    await setBool(keyFromUnit, fromUnit);
  }

  Future<void> saveUserData(String key, String value) async {
    await setString(key, value);
  }

  Future<String?> getUserData(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
