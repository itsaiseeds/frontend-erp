import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../data/clients_repository.dart';
import '../data/models/client.dart';
import '../../../core/widgets/loaders/shimmer_block.dart';
import 'client_form_screen.dart';
import 'widgets/client_status_badge.dart';
import 'widgets/detail_section.dart';

class ClientDetailScreen extends StatefulWidget {
  final String publicId;
  final Client? summary;

  const ClientDetailScreen({super.key, required this.publicId, this.summary});

  static Future<bool?> push(
    BuildContext context, {
    required String publicId,
    Client? summary,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            ClientDetailScreen(publicId: publicId, summary: summary),
      ),
    );
  }

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  late final ClientsRepository _repository;

  Client? _client;
  bool _isLoading = true;
  bool _didChange = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _client = widget.summary;
    _repository = ClientsRepository(apiClient: context.read<ApiClient>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Client client = await _repository.fetchClient(widget.publicId);
      if (!mounted) return;
      setState(() {
        _client = client;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppStrings.SOMETHING_WENT_WRONG;
      });
    }
  }

  Future<void> _edit() async {
    final Client? client = _client;
    if (client == null) return;

    final bool? saved = await ClientFormScreen.push(context, existing: client);
    if (saved ?? false) {
      _didChange = true;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Client? client = _client;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_didChange);
      },
      child: Scaffold(
        backgroundColor: AppColors.BACKGROUND,
        appBar: AppBar(
          backgroundColor: AppColors.SURFACE,
          surfaceTintColor: AppColors.TRANSPARENT,
          leading: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              size: AppSizes.ICON_XXL,
              color: AppColors.TEXT_PRIMARY,
            ),
            onPressed: () => Navigator.of(context).pop(_didChange),
          ),
          title: Text(
            AppStrings.CLIENT_DETAIL_TITLE,
            style: AppTypography.titleMedium,
          ),
          actions: [
            if (client != null)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.SM8),
                child: TextButton.icon(
                  onPressed: _edit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: AppSizes.ICON_MD,
                    color: AppColors.PRIMARY,
                  ),
                  label: Text(
                    AppStrings.CLIENT_EDIT,
                    style: AppTypography.button.copyWith(
                      color: AppColors.PRIMARY,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: _buildBody(client),
      ),
    );
  }

  Widget _buildBody(Client? client) {
    if (client == null && _errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.LG24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    if (client == null) return const _DetailShimmer();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.MD16,
            AppSpacing.MD16,
            AppSpacing.MD16,
            AppSpacing.SMD12,
          ),
          child: _IdentityCard(client: client, isRefreshing: _isLoading),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.PRIMARY,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.MD16,
                0,
                AppSpacing.MD16,
                AppSizes.CLIENT_LIST_BOTTOM_INSET,
              ),
              children: [
                DetailSection(
                  icon: Icons.location_city_outlined,
                  title: AppStrings.CLIENT_ADDRESSES,
                  count: client.addresses.length,
                  emptyMessage: AppStrings.CLIENT_NO_ADDRESS,
                  children: client.addresses
                      .map(
                        (address) => DetailRow(
                          title: address.label.isEmpty
                              ? address.cityWithState
                              : address.label,
                          subtitle: address.formatted,
                          isMain: address.isPrimary,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.MD16),
                DetailSection(
                  icon: Icons.person_outline_rounded,
                  title: AppStrings.CLIENT_CONTACTS,
                  count: client.contacts.length,
                  emptyMessage: AppStrings.CLIENT_DETAIL_NO_CONTACTS,
                  children: client.contacts
                      .map(
                        (contact) => DetailRow(
                          title: contact.name,
                          subtitle: [
                            contact.phoneNumber,
                            contact.role,
                          ].where((part) => part.isNotEmpty).join(' · '),
                          isMain: contact.isPrimary,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.MD16),
                DetailSection(
                  icon: Icons.local_shipping_outlined,
                  title: AppStrings.CLIENT_TRANSPORT,
                  count: client.transportAgencies.length,
                  emptyMessage: AppStrings.CLIENT_DETAIL_NO_TRANSPORT,
                  children: client.transportAgencies
                      .map(
                        (agency) => DetailRow(
                          title: agency.name,
                          subtitle: '',
                          isMain: agency.isPrimary,
                        ),
                      )
                      .toList(),
                ),
                if (client.createdBy.isNotEmpty ||
                    client.verifiedBy.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.MD16),
                  _AuditCard(client: client),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final Client client;
  final bool isRefreshing;

  const _IdentityCard({required this.client, this.isRefreshing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  client.companyName,
                  style: AppTypography.headingSmall,
                ),
              ),
              if (isRefreshing)
                const ShimmerBlock(
                  width: AppSizes.ICON_XXL,
                  height: AppSpacing.SM14,
                  radius: AppRadius.SM,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.SM8),
          ClientStatusBadge(status: client.status),
          const SizedBox(height: AppSpacing.SMD12),
          _MetaRow(icon: Icons.call_outlined, text: client.companyPhone),
          if (client.hasGstNumber) ...[
            const SizedBox(height: AppSpacing.XS6),
            _MetaRow(
              icon: Icons.verified_outlined,
              text: '${AppStrings.CLIENT_GST_LABEL} ${client.gstNumber}',
            ),
          ],
        ],
      ),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final Client client;

  const _AuditCard({required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      decoration: BoxDecoration(
        color: AppColors.SURFACE,
        border: Border.all(color: AppColors.BORDER),
        borderRadius: BorderRadius.circular(AppRadius.XL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (client.createdBy.isNotEmpty)
            _MetaRow(
              icon: Icons.person_add_alt_outlined,
              text: '${AppStrings.CLIENT_CREATED_BY} ${client.createdBy}',
            ),
          if (client.verifiedBy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.XS6),
            _MetaRow(
              icon: Icons.task_alt_rounded,
              text: '${AppStrings.CLIENT_VERIFIED_BY} ${client.verifiedBy}',
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppSizes.CLIENT_META_ICON,
          color: AppColors.TEXT_SECONDARY,
        ),
        const SizedBox(width: AppSpacing.XS6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.MD16),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.MD16),
          decoration: BoxDecoration(
            color: AppColors.SURFACE,
            border: Border.all(color: AppColors.BORDER),
            borderRadius: BorderRadius.circular(AppRadius.SEGMENT),
          ),
          child: const ShimmerLines(lines: 3),
        ),
        const SizedBox(height: AppSpacing.MD16),
        for (int index = 0; index < 3; index++) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.MD16),
            decoration: BoxDecoration(
              color: AppColors.SURFACE,
              border: Border.all(color: AppColors.BORDER),
              borderRadius: BorderRadius.circular(AppRadius.SEGMENT),
            ),
            child: const ShimmerLines(lines: 2),
          ),
          const SizedBox(height: AppSpacing.MD16),
        ],
      ],
    );
  }
}
