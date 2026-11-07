/// Centralized responsive layout breakpoints for WorkAxis.
///
/// Follows Material Design 3 and AGENTS.md project rules:
/// - Compact:  < 600dp (Android smartphones)
/// - Medium:   600dp - 839dp (Android tablets portrait & foldables)
/// - Expanded: >= 840dp (Large tablets landscape, desktop web)
abstract final class AppBreakpoints {
  /// Maximum width for compact devices (smartphones).
  static const double compactMax = 599.0;

  /// Minimum width for medium devices (tablets portrait).
  static const double mediumMin = 600.0;

  /// Maximum width for medium devices.
  static const double mediumMax = 839.0;

  /// Minimum width for expanded devices (desktop web, tablet landscape).
  static const double expandedMin = 840.0;

  /// Maximum comfortable content width for centered form cards on desktop/web.
  static const double maxFormCardWidth = 480.0;

  /// Maximum comfortable content width for structured listings/cards on desktop/web.
  static const double maxContentWidth = 1080.0;

  /// Maximum comfortable content width for primary operational/dashboard/catalog screens on desktop/web (matching Home page).
  static const double maxPageWidth = 1440.0;

  // Content-level layout thresholds (available width, not screen width).

  /// Width at which two-column form sections switch from stacked to split.
  static const double formSplit = 650.0;

  /// Width at which wide content compositions (side-by-side panels) begin.
  static const double wideContent = 900.0;

  /// Width at which detail screens switch to master/detail composition.
  static const double detailsSplit = 980.0;

  /// Width at which data tables replace card lists.
  static const double wideTable = 1000.0;

  /// Width at which the employee home uses its two-column composition.
  static const double employeeHomeWide = 1024.0;

  /// Width of the persistent navigation sidebar on expanded layouts.
  static const double sidebarWidth = 260.0;

  /// Height of the expanded-layout top console bar.
  static const double topBarHeight = 60.0;

  /// Content width below which attendance metric tiles use two columns.
  static const double metricTilesRow = 620.0;

  /// Content width at which branch snapshot rows show their progress bar.
  static const double snapshotBarMin = 420.0;
}
