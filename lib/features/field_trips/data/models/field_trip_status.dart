import '../../../../core/constants/app_strings.dart';

/// The four lifecycle codes a field trip moves through, plus a fallback so an
/// unknown code renders as itself rather than breaking the card.
enum FieldTripStatus { planned, approved, inProgress, completed, unknown }

class FieldTripStatusX {
  FieldTripStatusX._();

  static const String PLANNED = 'PLANNED';
  static const String APPROVED = 'APPROVED';
  static const String IN_PROGRESS = 'IN_PROGRESS';
  static const String COMPLETED = 'COMPLETED';

  /// The order the list filter offers, which is also the lifecycle order.
  static const List<FieldTripStatus> ORDERED = [
    FieldTripStatus.planned,
    FieldTripStatus.approved,
    FieldTripStatus.inProgress,
    FieldTripStatus.completed,
  ];

  static FieldTripStatus fromRaw(String raw) {
    switch (raw.trim().toUpperCase()) {
      case PLANNED:
        return FieldTripStatus.planned;
      case APPROVED:
        return FieldTripStatus.approved;
      case IN_PROGRESS:
        return FieldTripStatus.inProgress;
      case COMPLETED:
        return FieldTripStatus.completed;
      default:
        return FieldTripStatus.unknown;
    }
  }

  static String? rawOf(FieldTripStatus status) {
    switch (status) {
      case FieldTripStatus.planned:
        return PLANNED;
      case FieldTripStatus.approved:
        return APPROVED;
      case FieldTripStatus.inProgress:
        return IN_PROGRESS;
      case FieldTripStatus.completed:
        return COMPLETED;
      case FieldTripStatus.unknown:
        return null;
    }
  }

  static String labelOf(FieldTripStatus status) {
    switch (status) {
      case FieldTripStatus.planned:
        return AppStrings.FIELD_TRIP_STATUS_PLANNED;
      case FieldTripStatus.approved:
        return AppStrings.FIELD_TRIP_STATUS_APPROVED;
      case FieldTripStatus.inProgress:
        return AppStrings.FIELD_TRIP_STATUS_IN_PROGRESS;
      case FieldTripStatus.completed:
        return AppStrings.FIELD_TRIP_STATUS_COMPLETED;
      case FieldTripStatus.unknown:
        return AppStrings.FIELD_TRIP_STATUS_UNKNOWN;
    }
  }

  /// The plan is still editable until the trip is out: editing an approved
  /// trip is allowed, but withdraws its approval server-side.
  static bool canEdit(FieldTripStatus status) =>
      status == FieldTripStatus.planned || status == FieldTripStatus.approved;

  static bool canDelete(FieldTripStatus status) => canEdit(status);

  static bool canStart(FieldTripStatus status) =>
      status == FieldTripStatus.approved;

  static bool canEnd(FieldTripStatus status) =>
      status == FieldTripStatus.inProgress;

  /// Farmers can only be recorded while the salesperson is actually out.
  static bool canRecordFarmer(FieldTripStatus status) =>
      status == FieldTripStatus.inProgress;

  /// Editing this one costs the approval it already has, so the form warns
  /// before it opens.
  static bool withdrawsApproval(FieldTripStatus status) =>
      status == FieldTripStatus.approved;
}
