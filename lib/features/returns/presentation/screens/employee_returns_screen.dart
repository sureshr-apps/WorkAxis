import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_sliver_page.dart';
import 'package:workaxis/core/widgets/app_button.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/kpi/app_kpi_card.dart';
import 'package:workaxis/core/widgets/kpi/responsive_kpi_section.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/return_details_dialog.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_filter_bar.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_sliver_body.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_table.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/submit_return_dialog.dart';

/// Employee self-service returns: submit a request and track its status.
class EmployeeReturnsScreen extends StatefulWidget {
  const EmployeeReturnsScreen({super.key});

  @override
  State<EmployeeReturnsScreen> createState() => _EmployeeReturnsScreenState();
}

class _EmployeeReturnsScreenState extends State<EmployeeReturnsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ReturnsController>().searchQuery,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    await context.read<ReturnsController>().loadReturns(access: access);
  }

  void _openSubmitDialog() {
    final access = context.read<AccessController>().accessContext;
    if (access == null) return;
    final controller = context.read<ReturnsController>();
    controller.clearActionError();

    showDialog<bool>(
      context: context,
      builder: (_) => SubmitReturnDialog(
        onSubmit: (input) async {
          final saved = await controller.submitReturn(
            access: access,
            input: input,
          );
          if (!saved) {
            return controller.actionErrorMessage ??
                'The return request could not be submitted.';
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Return request submitted for manager review.'),
                backgroundColor: AppColors.statusActive,
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  void _showDetails(ReturnItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => ReturnDetailsDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReturnsController>();
    final hasPending = controller.pendingCount > 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: ResponsiveSliverPage(
          onRefresh: _loadData,
          slivers: [
            SliverToBoxAdapter(
              child: AppPageHeader(
                eyebrow: 'Self Service Operations',
                title: 'My Returns',
                subtitle: 'Submit returned products with proof of purchase and track status.',
                action: AppButton.responsive(
                  text: 'Submit Return',
                  iconData: Icons.add,
                  onPressed: _openSubmitDialog,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverToBoxAdapter(
              child: ResponsiveKpiSection(
                cards: [
                  AppKpiCard(
                    title: 'Pending review',
                    value: '${controller.pendingCount}',
                    accentColor: hasPending ? AppColors.statusUrgent : null,
                    icon: Icons.pending_actions_outlined,
                    iconColor: hasPending
                        ? AppColors.statusUrgentText
                        : AppColors.secondary,
                    iconBgColor: hasPending
                        ? AppColors.statusUrgentContainer
                        : AppColors.kpiNeutralBackground,
                    valueColor: hasPending ? AppColors.statusUrgentText : null,
                  ),
                  AppKpiCard(
                    title: 'Approved returns',
                    value: '${controller.approvedCount}',
                    accentColor: AppColors.statusActive,
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.statusActiveText,
                    iconBgColor: AppColors.statusActiveContainer,
                  ),
                  AppKpiCard(
                    title: 'Total submitted',
                    value: '${controller.totalCount}',
                    icon: Icons.assignment_return_outlined,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primaryContainer,
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            SliverToBoxAdapter(
              child: ReturnsFilterBar(
                controller: controller,
                searchController: _searchController,
                searchHint: 'Search product or bill number...',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            SliverReturnsBody(
              controller: controller,
              onOpen: _showDetails,
              onRetry: _loadData,
              emptyTitle: 'No return requests yet',
              emptyMessage:
                  'Tap "Submit Return" to file a new returned product request.',
              columns: [
                ReturnsTableColumn.product(),
                ReturnsTableColumn.quantity(),
                ReturnsTableColumn.invoice('Invoice / Bill #'),
                ReturnsTableColumn.branch(),
                ReturnsTableColumn.status(),
                ReturnsTableColumn.action(
                  canReview: false,
                  onOpen: _showDetails,
                ),
              ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}
