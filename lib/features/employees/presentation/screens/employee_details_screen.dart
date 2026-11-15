import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/app_page_header.dart';
import 'package:workaxis/core/widgets/page_breadcrumb.dart';
import 'package:workaxis/core/widgets/record_not_found_page.dart';
import 'package:workaxis/features/access/presentation/controllers/access_controller.dart';
import 'package:workaxis/features/access/presentation/controllers/branch_context_controller.dart';
import 'package:workaxis/features/employees/domain/models/organization_member.dart';
import 'package:workaxis/features/employees/presentation/controllers/organization_members_controller.dart';
import 'package:workaxis/features/employees/presentation/member_branch_names.dart';
import 'package:workaxis/features/employees/presentation/screens/widgets/member_details_view.dart';
import 'package:workaxis/shared/widgets/dashboard_surface_card.dart';

/// Full page for one organization account, reached from the employee directory.
/// [listRoute] and [listLabel] name the directory it came from, so the back
/// breadcrumb returns to the same scope (organization or branch).
class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.memberId,
    required this.listRoute,
    required this.listLabel,
  });

  final String memberId;
  final String listRoute;
  final String listLabel;

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  OrganizationMember? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(covariant EmployeeDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.memberId != widget.memberId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final access = context.read<AccessController>().accessContext;
    final branchId = context
        .read<BranchContextController>()
        .activeBranch
        ?.branchId;
    final member = access == null
        ? null
        : await context.read<OrganizationMembersController>().getMember(
            access: access,
            memberId: widget.memberId,
            activeBranchId: branchId,
          );
    if (!mounted) return;
    setState(() {
      _member = member;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final member = _member;
    if (member == null) return _notFound();

    final access = context.watch<AccessController>().accessContext;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageBreadcrumb(
                  backLabel: widget.listLabel,
                  currentLabel: member.fullName,
                  onBack: () => context.go(widget.listRoute),
                ),
                const SizedBox(height: AppSpacing.md),
                const AppPageHeader(
                  eyebrow: 'Employee Records',
                  title: 'Employee details',
                  subtitle: 'Profile and account access for this employee.',
                ),
                const SizedBox(height: AppSpacing.lg),
                DashboardSurfaceCard(
                  child: MemberDetailsView(
                    member: member,
                    branchNames: memberBranchNames(member, access),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _notFound() => RecordNotFoundPage(
    backLabel: widget.listLabel,
    currentLabel: 'Employee',
    onBack: () => context.go(widget.listRoute),
    message: 'This account could not be found.',
    onRetry: _load,
  );
}
