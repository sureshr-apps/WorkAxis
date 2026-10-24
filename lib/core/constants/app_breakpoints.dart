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
}
