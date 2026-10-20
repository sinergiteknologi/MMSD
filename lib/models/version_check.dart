class VersionCheck {
  const VersionCheck({
    required this.serverVersionCode,
    required this.serverVersionName,
    required this.isMandatory,
    required this.isUpgradeRequired,
  });

  final int serverVersionCode;
  final String serverVersionName;
  final bool isMandatory;
  final bool isUpgradeRequired;

  static VersionCheck? parse(String value, {required int currentVersionCode}) {
    final parts = value.split('/').map((part) => part.trim()).toList();
    if (parts.length < 3) return null;
    final serverCode = int.tryParse(parts[0]);
    if (serverCode == null) return null;
    final mandatory = parts[2].toLowerCase() == 'true';
    return VersionCheck(
      serverVersionCode: serverCode,
      serverVersionName: parts[1],
      isMandatory: mandatory,
      isUpgradeRequired: mandatory && serverCode > currentVersionCode,
    );
  }
}
