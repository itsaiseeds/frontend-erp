import '../../../core/constants/app_strings.dart';
import '../../../core/models/crop_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/field_trips_endpoints.dart';
import '../../../core/network/endpoints/products_endpoints.dart';
import '../../../core/network/endpoints/utilities_endpoints.dart';
import '../../products/data/models/paginated_products.dart';
import '../../products/data/models/product_packaging.dart';
import 'models/farmer_visit.dart';
import 'models/field_trip.dart';
import 'models/field_trip_status.dart';
import 'models/field_trips_query.dart';
import 'models/paginated_field_trips.dart';

class FieldTripsRepository {
  final ApiClient _apiClient;

  const FieldTripsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<PaginatedFieldTrips> fetchFieldTrips({
    required int page,
    required int pageSize,
    required FieldTripsQuery query,
  }) async {
    final dynamic response = await _apiClient.get(
      FieldTripsEndpoints.list,
      queryParams: query.toQueryParameters(page: page, pageSize: pageSize),
    );

    return PaginatedFieldTrips.fromJson(_asMap(response));
  }

  /// One trip by its public id, so a detail screen can refresh itself after
  /// an action without the caller holding a stale row.
  ///
  /// There is no detail endpoint, so this narrows the list with
  /// ``?public_id=``. That filter is a substring match, so the exact id is
  /// picked out of what comes back rather than trusting the first row.
  Future<FieldTrip?> fetchFieldTripByPublicId(String publicId) async {
    final String wanted = publicId.trim();
    if (wanted.isEmpty) return null;

    final dynamic response = await _apiClient.get(
      FieldTripsEndpoints.list,
      queryParams: {'public_id': wanted, 'page': 1, 'page_size': _LOOKUP_SIZE},
    );

    final PaginatedFieldTrips page = PaginatedFieldTrips.fromJson(
      _asMap(response),
    );

    for (final FieldTrip trip in page.results) {
      if (trip.publicId.toUpperCase() == wanted.toUpperCase()) return trip;
    }
    return null;
  }

  /// Whether a trip is already out, which the UI needs before offering to
  /// start another: the backend allows only one at a time per salesperson.
  Future<FieldTrip?> fetchRunningTrip() async {
    final dynamic response = await _apiClient.get(
      FieldTripsEndpoints.list,
      queryParams: {
        'status': FieldTripStatusX.IN_PROGRESS,
        'page': 1,
        'page_size': 1,
      },
    );

    final PaginatedFieldTrips page = PaginatedFieldTrips.fromJson(
      _asMap(response),
    );
    return page.results.isEmpty ? null : page.results.first;
  }

  Future<void> createFieldTrip({
    required int cityId,
    required String village,
    required DateTime expectedStartAt,
    required DateTime expectedEndAt,
  }) {
    return _apiClient.post(
      FieldTripsEndpoints.create,
      body: {
        'city_id': cityId,
        'village': village.trim(),
        'expected_start_at': expectedStartAt.toUtc().toIso8601String(),
        'expected_end_at': expectedEndAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> editFieldTrip({
    required String publicId,
    required int cityId,
    required String village,
    required DateTime expectedStartAt,
    required DateTime expectedEndAt,
  }) {
    return _apiClient.patch(
      FieldTripsEndpoints.edit(publicId),
      body: {
        'city_id': cityId,
        'village': village.trim(),
        'expected_start_at': expectedStartAt.toUtc().toIso8601String(),
        'expected_end_at': expectedEndAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> startFieldTrip(String publicId) =>
      _apiClient.post(FieldTripsEndpoints.start(publicId));

  Future<void> endFieldTrip(String publicId) =>
      _apiClient.post(FieldTripsEndpoints.end(publicId));

  Future<void> deleteFieldTrip(String publicId) =>
      _apiClient.delete(FieldTripsEndpoints.delete(publicId));

  /// Every farmer on one trip. The whole set is fetched at once -- a trip
  /// holds a day's visits, not a catalogue -- so the detail screen can show
  /// a real count without paging.
  Future<PaginatedFarmerVisits> fetchFarmerVisits(String publicId) async {
    final dynamic response = await _apiClient.get(
      FieldTripsEndpoints.farmerVisits(publicId),
      queryParams: {'all': true},
    );

    return PaginatedFarmerVisits.fromJson(_asMap(response));
  }

  Future<void> createFarmerVisit({
    required String fieldTripPublicId,
    required String farmerName,
    required String contactNumber,
    required String village,
    required String landAreaBigha,
    required List<int> cropIds,
    required List<String> productPublicIds,
  }) {
    return _apiClient.post(
      FieldTripsEndpoints.createFarmerVisit,
      body: {
        'field_trip_public_id': fieldTripPublicId,
        'farmer_name': farmerName.trim(),
        'contact_number': contactNumber.trim(),
        'village': village.trim(),
        'land_area_bigha': landAreaBigha,
        'crop_ids': cropIds,
        'product_public_ids': productPublicIds,
      },
    );
  }

  /// Changes a farmer already recorded on a running trip.
  ///
  /// A PATCH, so only what the user actually changed is sent -- passing an
  /// unchanged field back would make an accidental no-op edit look like a
  /// deliberate one in any future audit.
  Future<void> editFarmerVisit({
    required String publicId,
    String? farmerName,
    String? contactNumber,
    String? village,
    String? landAreaBigha,
    List<int>? cropIds,
    List<String>? productPublicIds,
  }) {
    return _apiClient.patch(
      FieldTripsEndpoints.editFarmerVisit(publicId),
      body: {
        if (farmerName != null) 'farmer_name': farmerName.trim(),
        if (contactNumber != null) 'contact_number': contactNumber.trim(),
        if (village != null) 'village': village.trim(),
        'land_area_bigha': ?landAreaBigha,
        'crop_ids': ?cropIds,
        'product_public_ids': ?productPublicIds,
      },
    );
  }

  Future<List<CropModel>> fetchCrops() async {
    final dynamic response = await _apiClient.get(UtilitiesEndpoints.crops);
    if (response is! List) return const [];

    return response
        .whereType<Map>()
        .map((entry) => CropModel.fromJson(Map<String, dynamic>.from(entry)))
        .where((crop) => crop.id > 0)
        .toList(growable: false);
  }

  /// The products a farmer can be marked as using. The catalogue is indexed
  /// by packaging, so the same product arrives once per bag size and is
  /// folded back down to one entry per product.
  Future<List<FarmerProduct>> fetchProducts() async {
    final dynamic response = await _apiClient.get(
      ProductsEndpoints.catalogue,
      queryParams: {'all': true},
    );

    final PaginatedProducts page = PaginatedProducts.fromJson(
      _asMap(response),
    );

    final Map<String, FarmerProduct> byPublicId = {};
    for (final ProductPackaging packaging in page.results) {
      final String id = packaging.productPublicId.trim();
      if (id.isEmpty || byPublicId.containsKey(id)) continue;
      byPublicId[id] = FarmerProduct(
        publicId: id,
        name: packaging.productName,
      );
    }

    final List<FarmerProduct> products = byPublicId.values.toList();
    products.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return products;
  }

  static const int _LOOKUP_SIZE = 20;

  static Map<String, dynamic> _asMap(dynamic response) {
    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }
    return Map<String, dynamic>.from(response);
  }
}
