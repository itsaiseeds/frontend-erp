import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/endpoints/godown_endpoints.dart';
import '../../../core/network/endpoints/utilities_endpoints.dart';
import 'models/godown_page.dart';
import 'models/godown_stock.dart';
import 'models/inward_other_material.dart';
import 'models/inward_raw_material.dart';
import 'models/inward_raw_status.dart';
import 'models/godown_pickable.dart';
import 'models/other_material_recipe.dart';
import 'models/product_packaging.dart';
import 'models/stock_position.dart';

/// Every godown-manager-token endpoint: stock positions, the two inward
/// lists, and the recipe picker. A sales-person token gets a 403 on every
/// one of these -- the server enforces the role split, not this class.
class GodownRepository {
  final ApiClient _apiClient;

  const GodownRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<RawMaterialStock> fetchRawMaterialStock({String? product}) async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.rawMaterialStock,
      queryParams: {'product': ?product},
    );
    return RawMaterialStock.fromJson(_asMap(response));
  }

  Future<OtherMaterialStock> fetchOtherMaterialStock({
    int? materialType,
  }) async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.otherMaterialStock,
      queryParams: {'material_type': ?materialType},
    );
    return OtherMaterialStock.fromJson(_asMap(response));
  }

  Future<GodownPage<InwardRawMaterial>> fetchInwardRawMaterials({
    required Map<String, dynamic> queryParams,
  }) async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.inwardRawMaterials,
      queryParams: queryParams,
    );
    return GodownPage.fromJson(_asMap(response), InwardRawMaterial.fromJson);
  }

  Future<void> createInwardRawMaterial({
    required String productPublicId,
    required int partyId,
    required String lotNo,
    required String quantityKg,
    String? farmerName,
    DateTime? labSamplingDate,
  }) {
    return _apiClient.post(
      GodownEndpoints.inwardRawMaterials,
      body: {
        'product': productPublicId,
        'party': partyId,
        'lot_no': lotNo.trim(),
        'quantity_kg': quantityKg,
        if (farmerName != null && farmerName.trim().isNotEmpty)
          'farmer_name': farmerName.trim(),
        'lab_sampling_date': ?_isoDate(labSamplingDate),
      },
    );
  }

  /// Only `lab_sampling_date` and `status` are accepted; the server ignores
  /// anything else. `status` goes over the wire as its display label
  /// ("In Use"), never a slug -- see `InwardRawStatusX.wireOf`.
  Future<void> updateInwardRawMaterialStatus({
    required String publicId,
    required InwardRawStatus status,
  }) {
    return _apiClient.patch(
      GodownEndpoints.inwardRawMaterial(publicId),
      body: {'status': InwardRawStatusX.wireOf(status)},
    );
  }

  Future<void> deleteInwardRawMaterial(String publicId) =>
      _apiClient.delete(GodownEndpoints.inwardRawMaterial(publicId));

  Future<GodownPage<InwardOtherMaterial>> fetchInwardOtherMaterials({
    required Map<String, dynamic> queryParams,
  }) async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.inwardOtherMaterials,
      queryParams: queryParams,
    );
    return GodownPage.fromJson(_asMap(response), InwardOtherMaterial.fromJson);
  }

  Future<void> createInwardOtherMaterial({
    required int partyId,
    required String recipePublicId,
    required String quantity,
  }) {
    return _apiClient.post(
      GodownEndpoints.inwardOtherMaterials,
      body: {'party': partyId, 'recipe': recipePublicId, 'quantity': quantity},
    );
  }

  /// PATCH has no writable fields on this endpoint; deleting and re-booking
  /// is the only correction. Kept only to mirror the admin counterpart --
  /// callers should not expose an edit affordance for this type.
  Future<void> deleteInwardOtherMaterial(String publicId) =>
      _apiClient.delete(GodownEndpoints.inwardOtherMaterial(publicId));

  /// Both lookups are open to either Android role (`AndroidSharedView`) and
  /// come back as a plain array -- no pagination, no `all=true` needed.
  Future<List<GodownPickableProduct>> fetchUsableProducts() async {
    final dynamic response = await _apiClient.get(UtilitiesEndpoints.products);
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map(
          (item) =>
              GodownPickableProduct.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((product) => product.isUsable)
        .toList();
  }

  /// Suppliers for the booking pickers. A [partyType] goes over the wire as
  /// the server's `type` filter (`RAW_MATERIAL` / `OTHER_MATERIAL`); the
  /// parsed rows are also kept down to that type, so a stale server that
  /// ignores the filter cannot put the wrong supplier in a picker.
  Future<List<GodownPickableParty>> fetchParties({String? partyType}) async {
    final dynamic response = await _apiClient.get(
      UtilitiesEndpoints.parties,
      queryParams: {'type': ?partyType},
    );
    if (response is! List) return const [];
    final List<GodownPickableParty> parties = response
        .whereType<Map>()
        .map(
          (item) =>
              GodownPickableParty.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final String type = partyType?.trim() ?? '';
    if (type.isEmpty) return parties;
    return parties.where((party) => party.partyType.trim() == type).toList();
  }

  /// `?all=true` for the whole catalogue in one page -- the picker inside
  /// the other-material booking form needs every recipe, not page one.
  Future<List<OtherMaterialRecipe>> fetchOtherMaterialRecipes() async {
    final GodownPage<OtherMaterialRecipe> page =
        await fetchOtherMaterialRecipesPage(queryParams: const {'all': true});
    return page.results;
  }

  /// The browsable, paginated, filterable form -- used by the recipes list
  /// screen, which needs `available_filters`/`available_sorts` and a real
  /// page size rather than the whole catalogue in one shot.
  Future<GodownPage<OtherMaterialRecipe>> fetchOtherMaterialRecipesPage({
    required Map<String, dynamic> queryParams,
  }) async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.otherMaterialRecipes,
      queryParams: queryParams,
    );
    return GodownPage.fromJson(_asMap(response), OtherMaterialRecipe.fromJson);
  }

  /// Whether today's sealed-bag count already exists. Drives the bag-stock
  /// POST (first write of the day) vs PATCH (amend) split -- packet stock has
  /// no equivalent server signal, see `PacketStockCubit._hasSubmittedToday`.
  Future<bool> fetchTodaysInventoryStatus() async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.checkTodaysInventory,
    );
    if (response is! Map) return false;
    return response['is_complete'] == true;
  }

  Future<List<GodownProductPackaging>> fetchProductPackagings() async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.productPackagings,
    );
    if (response is! List) return const [];
    return response
        .whereType<Map>()
        .map(
          (item) =>
              GodownProductPackaging.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Whole-day replace: packagings absent from [counts] are zeroed.
  Future<void> replaceBagStock(Map<String, int> counts) =>
      _apiClient.post(GodownEndpoints.updateBagStock, body: {'counts': counts});

  /// Only the named packagings are written; the rest of today's rows stand.
  Future<void> patchBagStock(Map<String, int> counts) => _apiClient.patch(
    GodownEndpoints.updateBagStock,
    body: {'counts': counts},
  );

  /// Whole-day replace: `(product, packet_weight)` pairs absent from [lines]
  /// are zeroed.
  Future<void> replacePacketStock(List<Map<String, dynamic>> lines) =>
      _apiClient.post(
        GodownEndpoints.updateSamplePacketStock,
        body: {'counts': lines},
      );

  /// Only the named `(product, packet_weight)` pairs are written.
  Future<void> patchPacketStock(List<Map<String, dynamic>> lines) => _apiClient
      .patch(GodownEndpoints.updateSamplePacketStock, body: {'counts': lines});

  /// The live bag position for every packaging counted at least once --
  /// absent entirely for one never counted, since the figures are derived
  /// from a snapshot row that does not yet exist.
  Future<List<BagStockPosition>> fetchBagStockPositions() async {
    final dynamic response = await _apiClient.get(GodownEndpoints.bagStock);
    if (response is! Map) return const [];
    final dynamic lines = response['lines'];
    if (lines is! List) return const [];
    return lines
        .whereType<Map>()
        .map(
          (item) => BagStockPosition.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// The live loose position for every `(product, packet_weight)` pool
  /// counted at least once.
  Future<List<PacketStockPosition>> fetchPacketStockPositions() async {
    final dynamic response = await _apiClient.get(
      GodownEndpoints.samplePacketStock,
    );
    if (response is! Map) return const [];
    final dynamic lines = response['lines'];
    if (lines is! List) return const [];
    return lines
        .whereType<Map>()
        .map(
          (item) =>
              PacketStockPosition.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static String? _isoDate(DateTime? value) {
    if (value == null) return null;
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Map<String, dynamic> _asMap(dynamic response) {
    if (response is! Map) {
      throw const ApiException(message: AppStrings.ERROR_UNEXPECTED_RESPONSE);
    }
    return Map<String, dynamic>.from(response);
  }
}
