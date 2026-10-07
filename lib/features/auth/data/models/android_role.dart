/// Which shell is on screen. Independent of what the server says a user is
/// allowed to be -- that lives on AuthSession -- this is just which one of
/// the allowed shells is currently chosen, for a user who holds both.
enum AndroidRole { salesPerson, godownManager, labTester }

extension AndroidRoleX on AndroidRole {
  static const String _salesPersonKey = 'sales_person';
  static const String _godownManagerKey = 'godown_manager';
  static const String _labTesterKey = 'lab_tester';

  String get storageKey => switch (this) {
    AndroidRole.salesPerson => _salesPersonKey,
    AndroidRole.godownManager => _godownManagerKey,
    AndroidRole.labTester => _labTesterKey,
  };

  static AndroidRole? fromStorageKey(String? key) => switch (key) {
    _salesPersonKey => AndroidRole.salesPerson,
    _godownManagerKey => AndroidRole.godownManager,
    _labTesterKey => AndroidRole.labTester,
    _ => null,
  };
}
