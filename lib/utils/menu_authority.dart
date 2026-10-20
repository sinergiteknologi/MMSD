class MenuAuthority {
  const MenuAuthority._(this.ids, this.allowAll);

  final Set<String> ids;
  final bool allowAll;

  factory MenuAuthority.parse(String value) {
    if (value.trim().isEmpty || value.trim() == "''") {
      return const MenuAuthority._({}, true);
    }
    final ids = value
        .split(',')
        .map((item) => item.replaceAll("'", '').trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    return MenuAuthority._(ids, false);
  }

  bool canAccess(String transactionId) =>
      allowAll || ids.contains(transactionId);
}
