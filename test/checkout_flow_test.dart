import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/features/clients/data/models/client.dart';
import 'package:frontend_erp/features/clients/data/models/client_address.dart';
import 'package:frontend_erp/features/clients/data/models/transport_agency.dart';
import 'package:frontend_erp/features/products/presentation/bloc/checkout_state.dart';

const _address = ClientAddress(id: 7, line1: 'Line 1', cityName: 'Rajkot');
const _client = Client(
  publicId: 'C-1',
  companyName: 'Acme',
  addresses: [_address],
  transportAgencies: [TransportAgency(id: 3, name: 'Speedy')],
);

void main() {
  group('checkout steps', () {
    test('starts on review', () {
      expect(const CheckoutState().step, CheckoutStep.review);
    });

    test('delivery is unresolved until a client and address are chosen', () {
      const empty = CheckoutState();
      expect(empty.isDeliveryResolved, isFalse);

      const clientOnly = CheckoutState(client: _client);
      expect(clientOnly.isDeliveryResolved, isFalse);

      const ready = CheckoutState(client: _client, address: _address);
      expect(ready.isDeliveryResolved, isTrue);
    });

    test('an address with no link id cannot be ordered against', () {
      const noId = CheckoutState(
        client: _client,
        address: ClientAddress(line1: 'Line 1'),
      );

      expect(noId.isDeliveryResolved, isFalse);
      expect(noId.canSubmit, isFalse);
    });

    test('submitting is blocked while a request is in flight', () {
      const submitting = CheckoutState(
        client: _client,
        address: _address,
        isSubmitting: true,
      );

      expect(submitting.canSubmit, isFalse);
      // The summary still shows; only the action is disabled.
      expect(submitting.isDeliveryResolved, isTrue);
    });

    test('options are the fetched links, not the client payload', () {
      // The list payload has no link arrays, so a freshly selected client
      // offers nothing until the pickers load. See
      // checkout_delivery_options_test.dart.
      const unloaded = CheckoutState(client: _client);
      expect(unloaded.addresses, isEmpty);
      expect(unloaded.agencies, isEmpty);

      const loaded = CheckoutState(
        client: _client,
        addresses: [_address],
        agencies: [TransportAgency(id: 3, name: 'Speedy')],
      );
      expect(loaded.addresses.single.id, 7);
      expect(loaded.agencies.single.id, 3);
    });
  });
}
