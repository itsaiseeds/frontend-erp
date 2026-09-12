import '../../../../core/constants/app_strings.dart';

enum ClientStatus { verified, verificationPending, unknown }

class ClientStatusX {
  ClientStatusX._();

  static const String VERIFIED = 'VERIFIED';
  static const String VERIFICATION_PENDING = 'VERIFICATION_PENDING';

  static ClientStatus fromRaw(String raw) {
    switch (raw) {
      case VERIFIED:
        return ClientStatus.verified;
      case VERIFICATION_PENDING:
        return ClientStatus.verificationPending;
      default:
        return ClientStatus.unknown;
    }
  }

  static String rawOf(ClientStatus status) {
    switch (status) {
      case ClientStatus.verified:
        return VERIFIED;
      case ClientStatus.verificationPending:
        return VERIFICATION_PENDING;
      case ClientStatus.unknown:
        return '';
    }
  }

  static String labelOf(ClientStatus status) {
    switch (status) {
      case ClientStatus.verified:
        return AppStrings.CLIENT_STATUS_VERIFIED;
      case ClientStatus.verificationPending:
        return AppStrings.CLIENT_STATUS_PENDING;
      case ClientStatus.unknown:
        return AppStrings.CLIENT_STATUS_UNKNOWN;
    }
  }
}
