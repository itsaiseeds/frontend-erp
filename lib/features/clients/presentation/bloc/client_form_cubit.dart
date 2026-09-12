import '../../../../core/bloc/safe_cubit.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/clients_repository.dart';
import '../../../../core/services/metadata_service.dart';
import '../../../../core/models/city_model.dart';
import '../../data/models/client.dart';
import '../../data/models/client_address.dart';
import '../../data/models/client_contact.dart';
import 'client_form_state.dart';

class ClientFormCubit extends SafeCubit<ClientFormState> {
  final ClientsRepository _repository;

  int _nextKey = 1;

  ClientFormCubit({required ClientsRepository repository, Client? existing})
    : _repository = repository,
      _existingPublicId = existing?.publicId,
      super(_initialStateFor(existing)) {
    if (existing != null) {
      _nextKey =
          existing.addresses.length +
          existing.contacts.length +
          existing.transportAgencies.length +
          1;
    }
  }

  final String? _existingPublicId;

  bool get isEditing =>
      _existingPublicId != null && _existingPublicId.isNotEmpty;

  int _takeKey() => _nextKey++;

  static ClientFormState _initialStateFor(Client? client) {
    if (client == null) return const ClientFormState();

    return ClientFormState(
      step: ClientFormStep.addresses,
      name: client.companyName,
      phoneNumber: client.companyPhone,
      gstNumber: client.gstNumber,
      addresses: client.addresses
          .asMap()
          .entries
          .map((entry) => _addressDraft(entry.key + 1, entry.value))
          .toList(),
      contacts: client.contacts
          .asMap()
          .entries
          .map(
            (entry) => _contactDraft(
              client.addresses.length + entry.key + 1,
              entry.value,
            ),
          )
          .toList(),
      transportAgencies: client.transportAgencies
          .asMap()
          .entries
          .map(
            (entry) => TransportDraft(
              key:
                  client.addresses.length +
                  client.contacts.length +
                  entry.key +
                  1,
              name: entry.value.name,
              isMain: entry.value.isPrimary,
            ),
          )
          .toList(),
    );
  }

  static AddressDraft _addressDraft(int key, ClientAddress address) {
    return AddressDraft(
      key: key,
      label: address.label,
      line1: address.line1,
      line2: address.line2,
      city: address.cityName.isEmpty
          ? null
          : CityModel(
              id: address.cityId,
              name: address.cityName,
              stateName: address.stateName,
              stateId: address.stateId,
            ),
      pincode: address.pincode,
      state: MetadataService.instance.stateById(address.stateId),
      country: MetadataService.instance.countryById(address.countryId),
      isMain: address.isPrimary,
    );
  }

  static ContactDraft _contactDraft(int key, ClientContact contact) {
    return ContactDraft(
      key: key,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
      role: contact.role,
      isMain: contact.isPrimary,
    );
  }

  void updateName(String value) => emit(state.copyWith(name: value));

  void updatePhoneNumber(String value) =>
      emit(state.copyWith(phoneNumber: value));

  void updateGstNumber(String value) => emit(state.copyWith(gstNumber: value));

  void goToStep(ClientFormStep step) => emit(state.copyWith(step: step));

  void nextStep() {
    if (state.isLastStep) return;
    emit(state.copyWith(step: ClientFormStep.values[state.stepIndex + 1]));
  }

  void previousStep() {
    if (state.step == firstEditableStep) return;
    emit(state.copyWith(step: ClientFormStep.values[state.stepIndex - 1]));
  }

  ClientFormStep get firstEditableStep =>
      isEditing ? ClientFormStep.addresses : ClientFormStep.details;

  bool get isOnFirstEditableStep => state.step == firstEditableStep;

  static List<T> _appended<T extends MainFlaggable>(List<T> items, T entry) {
    if (items.isEmpty) return [entry.withMain(true) as T];
    if (!entry.isMain) return [...items, entry];
    return [...items.map((item) => item.withMain(false) as T), entry];
  }

  static List<T> _replaced<T extends MainFlaggable>(
    List<T> items,
    int key,
    T entry,
  ) {
    final List<T> updated = items
        .map(
          (item) => item.key == key
              ? entry
              : (entry.isMain ? item.withMain(false) as T : item),
        )
        .toList();
    return _ensureSingleMain(updated);
  }

  static List<T> _withoutKey<T extends MainFlaggable>(List<T> items, int key) =>
      _ensureSingleMain(items.where((item) => item.key != key).toList());

  static List<T> _mainSetTo<T extends MainFlaggable>(List<T> items, int key) =>
      items.map((item) => item.withMain(item.key == key) as T).toList();

  static List<T> _ensureSingleMain<T extends MainFlaggable>(List<T> items) {
    if (items.isEmpty) return items;
    if (items.any((item) => item.isMain)) return items;
    return [items.first.withMain(true) as T, ...items.skip(1)];
  }

  void addAddress(AddressDraft draft) {
    emit(
      state.copyWith(
        addresses: _appended(state.addresses, draft.copyWith(key: _takeKey())),
      ),
    );
  }

  void updateAddress(int key, AddressDraft draft) {
    emit(
      state.copyWith(
        addresses: _replaced(state.addresses, key, draft.copyWith(key: key)),
      ),
    );
  }

  void removeAddress(int key) =>
      emit(state.copyWith(addresses: _withoutKey(state.addresses, key)));

  void setMainAddress(int key) =>
      emit(state.copyWith(addresses: _mainSetTo(state.addresses, key)));

  void addContact(ContactDraft draft) {
    emit(
      state.copyWith(
        contacts: _appended(state.contacts, draft.copyWith(key: _takeKey())),
      ),
    );
  }

  void updateContact(int key, ContactDraft draft) {
    emit(
      state.copyWith(
        contacts: _replaced(state.contacts, key, draft.copyWith(key: key)),
      ),
    );
  }

  void removeContact(int key) =>
      emit(state.copyWith(contacts: _withoutKey(state.contacts, key)));

  void setMainContact(int key) =>
      emit(state.copyWith(contacts: _mainSetTo(state.contacts, key)));

  void addTransportAgency(TransportDraft draft) {
    emit(
      state.copyWith(
        transportAgencies: _appended(
          state.transportAgencies,
          draft.copyWith(key: _takeKey()),
        ),
      ),
    );
  }

  void updateTransportAgency(int key, TransportDraft draft) {
    emit(
      state.copyWith(
        transportAgencies: _replaced(
          state.transportAgencies,
          key,
          draft.copyWith(key: key),
        ),
      ),
    );
  }

  void removeTransportAgency(int key) => emit(
    state.copyWith(
      transportAgencies: _withoutKey(state.transportAgencies, key),
    ),
  );

  void setMainTransportAgency(int key) => emit(
    state.copyWith(transportAgencies: _mainSetTo(state.transportAgencies, key)),
  );

  Future<void> submit() async {
    emit(state.copyWith(status: ClientFormStatus.submitting, clearError: true));

    try {
      final Client client = Client(
        publicId: _existingPublicId ?? '',
        companyName: state.name.trim(),
        companyPhone: state.phoneNumber.trim(),
        gstNumber: state.gstNumber.trim(),
        addresses: state.addresses.map((a) => a.toModel()).toList(),
        contacts: state.contacts.map((c) => c.toModel()).toList(),
        transportAgencies: state.transportAgencies
            .map((t) => t.toModel())
            .toList(),
      );

      if (isEditing) {
        await _repository.updateClient(client);
      } else {
        await _repository.createClient(client);
      }
      emit(state.copyWith(status: ClientFormStatus.success));
    } on ApiException catch (e) {
      final String message = e.message.trim();
      emit(
        state.copyWith(
          status: ClientFormStatus.failure,
          errorMessage: message.isEmpty
              ? AppStrings.CLIENT_SAVE_FAILED
              : message,
        ),
      );
    } catch (e) {
      AppLogger.session('failed to save client: $e');
      emit(
        state.copyWith(
          status: ClientFormStatus.failure,
          errorMessage: AppStrings.CLIENT_SAVE_FAILED,
        ),
      );
    }
  }
}
