import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../clients/data/clients_repository.dart';
import '../../../clients/data/models/client.dart';
import '../../../clients/data/models/client_address.dart';
import '../../../clients/data/models/client_status.dart';
import '../../../clients/data/models/clients_query.dart';
import '../../../clients/data/models/paginated_clients.dart';
import '../../../clients/data/models/transport_agency.dart';
import '../../data/models/cart_line.dart';
import '../../data/products_repository.dart';
import 'checkout_state.dart';

class CheckoutCubit extends SafeCubit<CheckoutState> {
  final ClientsRepository _clientsRepository;
  final ProductsRepository _productsRepository;

  CheckoutCubit({
    required ClientsRepository clientsRepository,
    required ProductsRepository productsRepository,
  }) : _clientsRepository = clientsRepository,
       _productsRepository = productsRepository,
       super(const CheckoutState());

  /// The picker shows every client the sales person can order for, so one
  /// generous page beats paging through a dropdown.
  static const int CLIENT_PAGE_SIZE = 30;

  Future<void> loadClients() async {
    emit(state.copyWith(status: CheckoutStatus.loading, clearError: true));

    try {
      final PaginatedClients result = await _clientsRepository.fetchClients(
        page: 1,
        pageSize: CLIENT_PAGE_SIZE,
        query: const ClientsQuery().withSelection(_STATUS_FILTER, {
          ClientStatusX.VERIFIED,
        }),
        rangeParamsByKey: const {},
      );

      emit(
        state.copyWith(status: CheckoutStatus.ready, clients: result.results),
      );
    } on ApiException catch (e) {
      _emitFailure(e.message);
    } catch (e) {
      AppLogger.session('failed to load clients for checkout: $e');
      _emitFailure(AppStrings.SOMETHING_WENT_WRONG);
    }
  }

  static const String _STATUS_FILTER = 'status';

  /// Picking a client replaces the address and agency options. Both are link
  /// ids scoped to that client and absent from the list payload, so they come
  /// from their own picker endpoints.
  Future<void> selectClient(Client client) async {
    if (state.client?.publicId == client.publicId) return;

    emit(
      state.copyWith(
        client: client,
        addresses: const [],
        agencies: const [],
        isLoadingLinks: true,
        clearAddress: true,
        clearAgency: true,
        clearValidation: true,
        clearError: true,
      ),
    );

    try {
      final List<ClientAddress> addresses = await _clientsRepository
          .fetchAddresses(client.publicId);
      final List<TransportAgency> agencies = await _clientsRepository
          .fetchTransportAgencies(client.publicId);

      if (state.client?.publicId != client.publicId) return;

      final ClientAddress? address = _primaryOf<ClientAddress>(
        addresses,
        (item) => item.isPrimary,
      );

      // Private dispatch is always offered, first and selected: booking
      // without an agency is the default assumption the backend makes.
      final List<TransportAgency> options = [
        TransportAgency.PRIVATE_DISPATCH,
        ...agencies,
      ];

      emit(
        state.copyWith(
          addresses: addresses,
          agencies: options,
          isLoadingLinks: false,
          address: address,
          clearAddress: address == null,
          agency: TransportAgency.PRIVATE_DISPATCH,
        ),
      );
    } on ApiException catch (e) {
      if (state.client?.publicId != client.publicId) return;
      emit(state.copyWith(isLoadingLinks: false, errorMessage: e.message));
    } catch (e) {
      AppLogger.session('failed to load delivery options: $e');
      if (state.client?.publicId != client.publicId) return;
      emit(
        state.copyWith(
          isLoadingLinks: false,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
    }
  }

  void selectAddress(ClientAddress address) =>
      emit(state.copyWith(address: address, clearValidation: true));

  void selectAgency(TransportAgency agency) =>
      emit(state.copyWith(agency: agency));

  void clearAgency() => emit(state.copyWith(clearAgency: true));

  void updateComments(String value) => emit(state.copyWith(comments: value));

  void goToDelivery() => emit(state.copyWith(step: CheckoutStep.delivery));

  void backToReview() => emit(state.copyWith(step: CheckoutStep.review));

  Future<bool> placeOrder(List<CartLine> lines) async {
    final Client? client = state.client;
    final ClientAddress? address = state.address;

    if (client == null) {
      emit(
        state.copyWith(
          validationMessage: AppStrings.VALIDATION_CLIENT_REQUIRED,
        ),
      );
      return false;
    }
    if (address == null || address.id == 0) {
      emit(
        state.copyWith(
          validationMessage: AppStrings.VALIDATION_ADDRESS_REQUIRED,
        ),
      );
      return false;
    }
    if (lines.isEmpty) return false;

    emit(state.copyWith(isSubmitting: true, clearError: true));

    try {
      await _productsRepository.createOrder(
        clientPublicId: client.publicId,
        clientAddressId: address.id,
        // Zero is the private-dispatch sentinel, never a real link id, so
        // the key is dropped and the backend books an own-vehicle dispatch.
        clientTransportAgencyId: state.agency?.isPrivateDispatch ?? true
            ? null
            : state.agency?.id,
        specialComments: state.comments,
        lines: lines,
      );

      emit(state.copyWith(isSubmitting: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.message));
      return false;
    } catch (e) {
      AppLogger.session('failed to place order: $e');
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: AppStrings.SOMETHING_WENT_WRONG,
        ),
      );
      return false;
    }
  }

  static T? _primaryOf<T>(List<T> items, bool Function(T) isPrimary) {
    if (items.isEmpty) return null;
    for (final T item in items) {
      if (isPrimary(item)) return item;
    }
    return items.first;
  }

  void _emitFailure(String message) {
    final String trimmed = message.trim();
    emit(
      state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: trimmed.isEmpty
            ? AppStrings.SOMETHING_WENT_WRONG
            : trimmed,
      ),
    );
  }
}
