import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/models/state_model.dart';

void main() {
  group('StateModel.fromJson', () {
    test('parses the states-with-nested-cities payload', () {
      final state = StateModel.fromJson({
        'id': 12,
        'name': 'Gujarat',
        'cities': [
          {'id': 101, 'name': 'Ahmedabad'},
          {'id': 102, 'name': 'Surat'},
        ],
      });

      expect(state.id, 12);
      expect(state.name, 'Gujarat');
      expect(state.cities, hasLength(2));
      expect(state.cities.first.name, 'Ahmedabad');
    });

    test('stamps the parent state name onto every nested city', () {
      final state = StateModel.fromJson({
        'id': 12,
        'name': 'Gujarat',
        'cities': [
          {'id': 101, 'name': 'Ahmedabad'},
        ],
      });

      expect(state.cities.single.stateName, 'Gujarat');
    });

    test('yields an empty city list when the key is missing', () {
      final state = StateModel.fromJson({'id': 1, 'name': 'Goa'});

      expect(state.cities, isEmpty);
    });

    test('skips malformed city entries instead of throwing', () {
      final state = StateModel.fromJson({
        'id': 1,
        'name': 'Goa',
        'cities': [
          {'id': 5, 'name': 'Panaji'},
          'not-a-map',
          42,
        ],
      });

      expect(state.cities, hasLength(1));
      expect(state.cities.single.name, 'Panaji');
    });

    test('coerces a string id and tolerates a missing name', () {
      final state = StateModel.fromJson({
        'id': '9',
        'cities': [
          {'id': '77'},
        ],
      });

      expect(state.id, 9);
      expect(state.name, '');
      expect(state.cities.single.id, 77);
      expect(state.cities.single.name, '');
    });

    test('cities compare by id so they work as dropdown values', () {
      const a = StateModel(id: 1, name: 'A');
      final first = StateModel.fromJson({
        'id': 1,
        'name': 'Gujarat',
        'cities': [
          {'id': 101, 'name': 'Ahmedabad'},
        ],
      });
      final second = StateModel.fromJson({
        'id': 1,
        'name': 'Gujarat',
        'cities': [
          {'id': 101, 'name': 'Ahmedabad'},
        ],
      });

      expect(a.cities, isEmpty);
      expect(first.cities.single, equals(second.cities.single));
    });
  });
}
