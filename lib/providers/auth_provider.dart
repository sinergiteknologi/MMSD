import 'package:flutter/material.dart';

import '../models/bisnis_option.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/pref_service.dart';
import '../utils/app_config.dart';
import '../utils/menu_authority.dart';
import '../utils/xml_parser.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({
    ApiService? apiService,
    PrefService? prefService,
    DatabaseService? databaseService,
  }) : _apiService = apiService ?? ApiService(),
       _prefService = prefService ?? PrefService(),
       _dbService = databaseService ?? DatabaseService();

  final ApiService _apiService;
  final PrefService _prefService;
  final DatabaseService _dbService;

  UserModel? _user;
  bool _isLoading = false;
  String _loadingMessage = '';
  String _errorMessage = '';
  List<BisnisOption> _bisnisList = [];
  String _mainAut = '';
  MenuAuthority _menuAuthority = MenuAuthority.parse('');

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get loadingMessage => _loadingMessage;
  String get errorMessage => _errorMessage;
  List<BisnisOption> get bisnisList => _bisnisList;
  bool get isLoggedIn => _user != null;
  ApiService get apiService => _apiService;
  String get mainAut => _mainAut;

  bool canAccess(String tranIdx) {
    return _menuAuthority.canAccess(tranIdx);
  }

  bool hasTranIdx(String tranIdx) => _mainAut.contains("'$tranIdx'");

  void _setMainAuthority(String value) {
    _mainAut = value;
    _menuAuthority = MenuAuthority.parse(value);
  }

  Future<void> loadBisnis() async {
    _isLoading = true;
    _loadingMessage = 'Memuat data bisnis...';
    _errorMessage = '';
    _bisnisList = [];
    notifyListeners();
    try {
      _apiService.configure(server: AppConfig.defaultServiceHost, bisnis: '');
      final response = await _apiService.getBisnis();
      if (response != null) {
        _bisnisList = XmlParser.parseBisnis(response);
        if (_bisnisList.isEmpty) {
          _errorMessage = 'Daftar bisnis dari layanan tidak valid.';
        }
      } else {
        _errorMessage = _apiService.lastErrorMessage;
      }
    } catch (error) {
      _errorMessage = 'Gagal mengambil data bisnis: $error';
    }
    _isLoading = false;
    _loadingMessage = '';
    notifyListeners();
  }

  Future<bool> restoreSession() async {
    final loggedIn = await _prefService.getLoginStatus();
    if (!loggedIn) return false;
    final username = await _prefService.getString(PrefService.keyUsername);
    final busCode = await _prefService.getString(PrefService.keyBusCode);
    if (username.isEmpty || busCode.isEmpty) return false;
    final server = await _prefService.getString(PrefService.keyServer);
    final bisnis = await _prefService.getString(PrefService.keyBisnis);
    _apiService.configure(server: server, bisnis: bisnis);
    _user = UserModel(
      username: username,
      password: await _prefService.getString(PrefService.keyPassword),
      busCode: busCode,
      busName: await _prefService.getString(PrefService.keyBusName),
      salesCode: await _prefService.getString(PrefService.keySalesCode),
      salesName: await _prefService.getString(PrefService.keySalesName),
      branchAut: await _prefService.getString(PrefService.keyBusAut),
      authority: await _prefService.getString(PrefService.keyAuthority),
      userGroup: await _prefService.getString(PrefService.keyUserGroup),
      userStatus: await _prefService.getString(PrefService.keyUserStatus),
      branchNameAut: await _prefService.getString(PrefService.keyBusNameAut),
    );
    _setMainAuthority(await _prefService.getString(PrefService.keyMainAut));
    notifyListeners();
    return true;
  }

  Future<bool> login({
    required BisnisOption bisnis,
    required String username,
    required String password,
    String cabang = AppConfig.defaultCabang,
  }) async {
    _isLoading = true;
    _loadingMessage = 'Sedang masuk...';
    _errorMessage = '';
    notifyListeners();

    try {
      var userName = username;
      if (userName.startsWith('#') && userName.endsWith('#')) {
        userName = userName.replaceAll('#', '');
      }

      await _prefService.saveServer(bisnis.server, bisnis.code);
      _apiService.configure(server: bisnis.server, bisnis: bisnis.code);
      print('apiService.configure: ${bisnis.server} ${bisnis.code}');
      final response = await _apiService.login(
        sCabang: cabang,
        sUser: userName,
        sPwd: password,
      );

      if (response != null) {
        final parsed = XmlParser.parseLogin(
          xmlString: response,
          username: userName,
          password: password,
        );
        if (parsed != null) {
          _user = parsed;
          await _prefService.saveLoginData(
            username: parsed.username,
            password: parsed.password,
            busCode: parsed.busCode,
            busName: parsed.busName,
            salesCode: parsed.salesCode,
            salesName: parsed.salesName,
            busAut: parsed.branchAut,
            authority: parsed.authority,
            userGroup: parsed.userGroup,
            userStatus: parsed.userStatus,
            busNameAut: parsed.branchNameAut,
          );
          await _dbService.clearTable('M_LOGIN');
          _setMainAuthority(
            await _prefService.getString(PrefService.keyMainAut),
          );
          await _dbService.addLogin({
            'Login': 'YES',
            'UserNam': parsed.username,
            'UserPwd': parsed.password,
            'BranchCode': parsed.busCode,
            'BranchName': parsed.busName,
            'SalesCode': parsed.salesCode,
            'SalesName': parsed.salesName,
            'BranchAut': parsed.branchAut,
            'UserAut': parsed.authority,
            'UserGroup': parsed.userGroup,
            'UserStatus': parsed.userStatus,
            'BranchNameAut': parsed.branchNameAut,
          });
          _isLoading = false;
          _loadingMessage = '';
          notifyListeners();
          return true;
        }
      }
      _errorMessage = _apiService.lastFailure == null
          ? 'Login gagal. Periksa user dan password.'
          : _apiService.lastErrorMessage;
    } catch (error) {
      _errorMessage = 'Login gagal: $error';
    }

    _isLoading = false;
    _loadingMessage = '';
    notifyListeners();
    return false;
  }

  Future<bool> changePassword(String newPassword) async {
    if (_user == null) return false;
    _isLoading = true;
    notifyListeners();
    final response = await _apiService.uploadNewPassword(
      user: _user!.username,
      newPassword: newPassword,
    );
    final success = response != null && XmlParser.parseStatus(response);
    if (success) {
      await _prefService.setString(PrefService.keyPassword, newPassword);
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> logout() async {
    await _prefService.clearAll();
    await _dbService.clearAllTables();
    _user = null;
    _bisnisList = [];
    _setMainAuthority('');
    _apiService.configure(server: AppConfig.defaultServiceHost, bisnis: '');
    notifyListeners();
  }
}
