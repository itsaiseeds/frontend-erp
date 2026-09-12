import 'package:flutter/foundation.dart';

import '../models/city_model.dart';
import '../models/country_model.dart';
import '../models/state_model.dart';
import '../network/api_client.dart';
import '../network/endpoints/utilities_endpoints.dart';
import '../utils/app_logger.dart';

enum MetadataStatus { idle, loading, ready, failed }

class MetadataService {
  MetadataService._();

  static final MetadataService instance = MetadataService._();

  final ValueNotifier<MetadataStatus> statusListenable =
      ValueNotifier<MetadataStatus>(MetadataStatus.idle);

  ApiClient? _apiClient;

  List<CountryModel> _countries = const [];
  List<StateModel> _states = const [];
  final Map<int, CityModel> _citiesById = {};

  Future<void>? _inFlight;

  set apiClient(ApiClient client) => _apiClient = client;

  MetadataStatus get status => statusListenable.value;

  bool get isReady => status == MetadataStatus.ready;

  List<CountryModel> get countries => List.unmodifiable(_countries);

  List<StateModel> get states => List.unmodifiable(_states);

  List<CityModel> get cities => List.unmodifiable(_citiesById.values);

  CityModel? cityById(int? id) => id == null ? null : _citiesById[id];

  List<StateModel> statesInCountry(int? countryId) {
    if (countryId == null || countryId == 0) return states;
    return _states
        .where((state) => state.countryId == 0 || state.countryId == countryId)
        .toList(growable: false);
  }

  List<CityModel> citiesInState(int? stateId) {
    if (stateId == null || stateId == 0) return cities;
    return _citiesById.values
        .where((city) => city.stateId == stateId)
        .toList(growable: false);
  }

  CountryModel? countryById(int? id) {
    if (id == null) return null;
    for (final country in _countries) {
      if (country.id == id) return country;
    }
    return null;
  }

  StateModel? stateById(int? id) {
    if (id == null) return null;
    for (final state in _states) {
      if (state.id == id) return state;
    }
    return null;
  }

  Future<void> ensureLoaded({bool forceRefresh = false}) {
    if (!forceRefresh && status == MetadataStatus.ready) {
      return Future<void>.value();
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<void> _load() async {
    statusListenable.value = MetadataStatus.loading;
    final ApiClient client = _apiClient ??= ApiClient();

    try {
      final List<dynamic> responses = await Future.wait([
        client.get(UtilitiesEndpoints.countries),
        client.get(UtilitiesEndpoints.states),
        client.get(UtilitiesEndpoints.cities),
      ]);

      _countries = _parse(responses[0], CountryModel.fromJson);
      _states = _parse(responses[1], StateModel.fromJson);

      final List<StateModel> grouped = _parse(
        responses[2],
        StateModel.fromJson,
      );

      _citiesById
        ..clear()
        ..addEntries(
          grouped
              .expand((state) => state.cities)
              .map((city) => MapEntry(city.id, city)),
        );

      if (_states.isEmpty) _states = grouped;

      statusListenable.value = MetadataStatus.ready;
    } catch (e) {
      AppLogger.session('failed to load metadata: $e');
      statusListenable.value = MetadataStatus.failed;
    }
  }

  static List<T> _parse<T>(
    dynamic response,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map((entry) => parser(Map<String, dynamic>.from(entry)))
        .toList(growable: false);
  }

  void reset() {
    _countries = const [];
    _states = const [];
    _citiesById.clear();
    statusListenable.value = MetadataStatus.idle;
  }
}
