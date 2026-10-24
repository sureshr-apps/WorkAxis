import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workaxis/app/theme/app_colors.dart';
import 'package:workaxis/app/theme/app_spacing.dart';
import 'package:workaxis/core/responsive/responsive_layout.dart';
import 'package:workaxis/core/widgets/error_banner.dart';
import 'package:workaxis/features/platform_dashboard/presentation/controllers/platform_dashboard_controller.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/platform_kpi_carousel.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/platform_overview_hero_banner.dart';
import 'package:workaxis/features/platform_dashboard/presentation/screens/widgets/recent_organizations_list.dart';

/// Home dashboard for Platform Owner and Platform Administrator roles.
class PlatformHomeScreen extends StatefulWidget {
  const PlatformHomeScreen({super.key});

  @override
  State<PlatformHomeScreen> createState() => _PlatformHomeScreenState();
}

class _PlatformHomeScreenState extends State<PlatformHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PlatformDashboardController>();
      if (controller.status == PlatformDashboardStatus.initial) {
        controller.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlatformDashboardController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: () => controller.loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsivePageContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Executive Command Center Hero Banner
                const PlatformOverviewHeroBanner(),
                const SizedBox(height: AppSpacing.xl),

                if (controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.hasError) ...[
                  ErrorBanner(
                    message:
                        controller.errorMessage ??
                        'An error occurred loading the dashboard.',
                    onRetry: () => controller.loadDashboard(),
                  ),
                ] else if (controller.summary != null) ...[
                  // KPI Section with top border accents and progress telemetry
                  PlatformKpiCarousel(summary: controller.summary!),
                  const SizedBox(height: AppSpacing.xl),

                  // Recent Customer Organizations Master Table Panel
                  RecentOrganizationsList(
                    organizations: controller.recentOrganizations,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
