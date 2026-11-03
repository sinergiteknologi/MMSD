class BisnisOption {
  final String code;
  final String name;
  final String dbServer;

  const BisnisOption({
    required this.code,
    required this.name,
    required this.dbServer,
  });

  @override
  bool operator ==(Object other) =>
      other is BisnisOption &&
      other.code == code &&
      other.name == name &&
      other.dbServer == dbServer;

  @override
  int get hashCode => Object.hash(code, name, dbServer);
}
