class SpkListAction {
  static const edit = 'EDIT';
  static const approved1 = 'APPROVED1';
  static const approved2 = 'APPROVED2';
  static const view = 'VIEW';
  static const create = 'NEW';

  static bool isApprovedStatus(String status) =>
      status.trim().toLowerCase() == 'approved';

  static String resolve({
    required String userStatus,
    required String spkStatus,
  }) {
    final role = userStatus.trim();
    final status = spkStatus.trim();
    if (role == 'Sales' && status == 'Waiting App 1') return edit;
    if (role == 'SPV' && status == 'Waiting App 1') return approved1;
    if (role == 'BM' && status == 'Waiting App 2') return approved2;
    return view;
  }

  static bool canEdit(String action) =>
      action == create || action == edit;

  static bool canSave(String action) => action != view;

  static String saveLabel(String action) {
    if (action.contains('APPROVED')) return 'Approved';
    if (action == edit) return 'Update';
    return 'Create SPK';
  }
}
