class BisnisOption {
  final String code;
  final String name;
  final String server;

  const BisnisOption({
    required this.code,
    required this.name,
    required this.server,
  });

  @override
  bool operator ==(Object other) =>
      other is BisnisOption &&
      other.code == code &&
      other.name == name &&
      other.server == server;

  @override
  int get hashCode => Object.hash(code, name, server);
}
