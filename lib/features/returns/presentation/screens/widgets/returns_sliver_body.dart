import 'package:flutter/material.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/widgets/empty_state.dart';
import 'package:workaxis/core/widgets/error_state.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';
import 'package:workaxis/features/returns/presentation/controllers/returns_controller.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_sliver_list.dart';
import 'package:workaxis/features/returns/presentation/screens/widgets/returns_table.dart';

/// Loading / error / empty / data switch shared by the returns screens.
class SliverReturnsBody extends StatelessWidget {
  const SliverReturnsBody({
    super.key,
    required this.controller,
    required this.columns,
    required this.onOpen,
    required this.onRetry,
    required this.emptyTitle,
    required this.emptyMessage,
    this.showReviewAction = false,
  });

  final ReturnsController controller;
  final List<ReturnsTableColumn> columns;
  final void Function(ReturnItem item) onOpen;
  final VoidCallback onRetry;
  final String emptyTitle;
  final String emptyMessage;
  final bool showReviewAction;

  @override
  Widget build(BuildContext context) {
    final error = controller.errorMessage;
    if (controller.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (error != null) {
      return SliverToBoxAdapter(
        child: ErrorState(message: error, onRetry: onRetry),
      );
    }
    final items = controller.filteredItems;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.assignment_return_outlined,
          title: emptyTitle,
          message: emptyMessage,
        ),
      );
    }
    return SliverReturnsList(
      items: items,
      columns: columns,
      onOpen: onOpen,
      showReviewAction: showReviewAction,
    );
  }
}
