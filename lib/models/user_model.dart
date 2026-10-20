class UserModel {
  final String username;
  final String password;
  final String busCode;
  final String busName;
  final String salesCode;
  final String salesName;
  final String branchAut;
  final String authority;
  final String userGroup;
  final String userStatus;
  final String branchNameAut;

  const UserModel({
    required this.username,
    this.password = '',
    required this.busCode,
    required this.busName,
    required this.salesCode,
    required this.salesName,
    this.branchAut = '',
    required this.authority,
    required this.userGroup,
    this.userStatus = '',
    this.branchNameAut = '',
  });

  bool get isValid => busCode.isNotEmpty;

  String get historyBranch => branchAut.isNotEmpty ? branchAut : busCode;

  factory UserModel.fromLoginXml({
    required String username,
    required String password,
    required String kodeCabang,
    required String namaCabang,
    required String salesCode,
    required String salesName,
    required String branchAut,
    required String mobileAut,
    required String userGroup,
    required String userStatus,
    required String branchNameAut,
  }) {
    return UserModel(
      username: username,
      password: password,
      busCode: kodeCabang,
      busName: namaCabang,
      salesCode: salesCode,
      salesName: salesName,
      branchAut: branchAut,
      authority: mobileAut,
      userGroup: userGroup,
      userStatus: userStatus,
      branchNameAut: branchNameAut,
    );
  }
}
