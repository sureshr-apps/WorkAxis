/// A license change that has its own page. [routeSegment] is the last part of
/// its URL, so the route and the tab agree on the same spelling.
enum OrganizationLicenseAction {
  assign('assign'),
  changePlan('change-plan'),
  commercialTerms('commercial-terms'),
  renew('renew');

  const OrganizationLicenseAction(this.routeSegment);

  final String routeSegment;

  /// The action named in a URL, or null when the URL names none.
  static OrganizationLicenseAction? fromRouteSegment(String segment) {
    for (final action in values) {
      if (action.routeSegment == segment) return action;
    }
    return null;
  }
}
