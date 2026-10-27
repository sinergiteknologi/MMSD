class SpkListAction {
  static const edit = 'EDIT';
  static const approved1 = 'APPROVED1';
  static const approved2 = 'APPROVED2';
  static const view = 'VIEW';
  static const create = 'NEW';

  static bool isApprovedStatus(String status) =>
      status.trim().toLowerCase() == 'approved';

  static bool isApproveAction(String action) =>
      action.toUpperCase().contains('APPROVED');

  static String resolve({
    required String userStatus,
    required String spkStatus,
  }) {
    final role = userStatus.trim().toUpperCase();
    final status = spkStatus.trim().toLowerCase();
    if (role == 'SALES' && status == 'waiting app 1') return edit;
    if (role == 'SPV' && status == 'waiting app 1') return approved1;
    if (role == 'BM' && status == 'waiting app 2') return approved2;
    return view;
  }

  static bool canEdit(String action) =>
      action == create || action == edit;

  static bool canSave(String action) => action != view;

  static String saveLabel(String action) {
    if (isApproveAction(action)) return 'Approve';
    if (action == edit) return 'Update';
    return 'Create SPK';
  }

  static String listActionLabel({
    required String userStatus,
    required String spkStatus,
  }) {
    final action = resolve(userStatus: userStatus, spkStatus: spkStatus);
    if (isApproveAction(action)) return 'Approve';
    if (action == edit) return 'Edit';
    if (isApprovedStatus(spkStatus)) return 'View Indent';
    return 'Select';
  }
}
