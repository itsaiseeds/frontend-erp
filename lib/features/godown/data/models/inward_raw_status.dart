import '../../../../core/constants/app_strings.dart';

/// The three states a raw-material lot moves through, plus a fallback so an
/// unrecognised code still renders.
enum InwardRawStatus { labTesting, inUse, rejected, unknown }

class InwardRawStatusX {
  InwardRawStatusX._();

  /// The API sends and accepts the display label, not a slug: a PATCH with
  /// `in_use` comes back as `"in_use" is not a valid choice`.
  static const String LAB_TESTING_WIRE = 'Lab Testing';
  static const String IN_USE_WIRE = 'In Use';
  static const String REJECTED_WIRE = 'Rejected';

  static const List<InwardRawStatus> ORDERED = [
    InwardRawStatus.labTesting,
    InwardRawStatus.inUse,
    InwardRawStatus.rejected,
  ];

  static InwardRawStatus fromRaw(String raw) {
    switch (raw.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_')) {
      case 'lab_testing':
        return InwardRawStatus.labTesting;
      case 'in_use':
        return InwardRawStatus.inUse;
      case 'rejected':
        return InwardRawStatus.rejected;
      default:
        return InwardRawStatus.unknown;
    }
  }

  static String? wireOf(InwardRawStatus status) {
    switch (status) {
      case InwardRawStatus.labTesting:
        return LAB_TESTING_WIRE;
      case InwardRawStatus.inUse:
        return IN_USE_WIRE;
      case InwardRawStatus.rejected:
        return REJECTED_WIRE;
      case InwardRawStatus.unknown:
        return null;
    }
  }

  static String labelOf(InwardRawStatus status) {
    switch (status) {
      case InwardRawStatus.labTesting:
        return AppStrings.GODOWN_STATUS_LAB_TESTING;
      case InwardRawStatus.inUse:
        return AppStrings.GODOWN_STATUS_IN_USE;
      case InwardRawStatus.rejected:
        return AppStrings.GODOWN_STATUS_REJECTED;
      case InwardRawStatus.unknown:
        return AppStrings.GODOWN_STATUS_UNKNOWN;
    }
  }

  /// Lab Testing is the hub of the lifecycle: a settled lot only ever
  /// reverts to it, never crosses straight to the other settled state.
  /// Mirrors `InwardOperations.ALLOWED_RAW_STATUS_TRANSITIONS`.
  static List<InwardRawStatus> allowedNextFrom(InwardRawStatus status) {
    switch (status) {
      case InwardRawStatus.labTesting:
        return const [InwardRawStatus.inUse, InwardRawStatus.rejected];
      case InwardRawStatus.inUse:
      case InwardRawStatus.rejected:
        return const [InwardRawStatus.labTesting];
      case InwardRawStatus.unknown:
        return const [];
    }
  }

  /// Only the two dated statuses carry an effective date; the server stamps
  /// it with today on the way in and clears it on the way back out.
  static bool isDated(InwardRawStatus status) =>
      status == InwardRawStatus.inUse || status == InwardRawStatus.rejected;
}
