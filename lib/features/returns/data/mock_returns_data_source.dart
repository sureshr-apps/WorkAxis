import 'package:workaxis/features/returns/domain/models/return_item.dart';

class MockReturnsDataSource {
  final List<ReturnItem> _returns = [
    ReturnItem(
      id: 'RET-001',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-dt-01',
      branchName: 'Downtown Flagship',
      employeeId: 'emp-101',
      employeeName: 'Marcus Vance',
      productTitle: 'Organic Fuji Apples (Batch #FA-902)',
      reason: ReturnReason.damaged,
      quantity: 12.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8812',
      returnDate: DateTime.now().subtract(const Duration(hours: 3)),
      status: ReturnStatus.pending,
      remarks: 'Bruised during cold-chain transfer from primary distribution center.',
    ),
    ReturnItem(
      id: 'RET-002',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-dt-01',
      branchName: 'Downtown Flagship',
      employeeId: 'emp-102',
      employeeName: 'Sarah Jenkins',
      productTitle: 'Fresh Whole Milk 1L (Crate 4)',
      reason: ReturnReason.expired,
      quantity: 24.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8809',
      returnDate: DateTime.now().subtract(const Duration(hours: 5)),
      status: ReturnStatus.pending,
      remarks: 'Product reached best-before date prior to display stocking.',
    ),
    ReturnItem(
      id: 'RET-003',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-dt-01',
      branchName: 'Downtown Flagship',
      employeeId: 'emp-101',
      employeeName: 'Marcus Vance',
      productTitle: 'Valencia Navel Oranges (Box #VO-114)',
      reason: ReturnReason.customerReturned,
      quantity: 18.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8790',
      returnDate: DateTime.now().subtract(const Duration(days: 1)),
      status: ReturnStatus.approved,
      remarks: 'Customer returned sealed crate with proof of purchase.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes: 'Verified receipt and crate condition. Store credit approved.',
      reviewedAt: DateTime.now().subtract(const Duration(hours: 18)),
    ),
    ReturnItem(
      id: 'RET-004',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-ns-02',
      branchName: 'North Suburb Terminal',
      employeeId: 'emp-103',
      employeeName: 'David Kim',
      productTitle: 'Imported Hass Avocados (Case #HA-40)',
      reason: ReturnReason.damaged,
      quantity: 8.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8765',
      returnDate: DateTime.now().subtract(const Duration(days: 2)),
      status: ReturnStatus.rejected,
      remarks: 'Overripe condition discovered after customer delivery.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes: 'Exceeded 48-hour return window for perishable category.',
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ReturnItem(
      id: 'RET-005',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-ns-02',
      branchName: 'North Suburb Terminal',
      employeeId: 'emp-104',
      employeeName: 'Amina Idris',
      productTitle: 'Artisan Sourdough Loaves',
      reason: ReturnReason.expired,
      quantity: 15.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8740',
      returnDate: DateTime.now().subtract(const Duration(days: 2)),
      status: ReturnStatus.approved,
      remarks: 'Bakery surplus past shelf-life threshold.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes: 'Write-off verified for compost diversion.',
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ReturnItem(
      id: 'RET-006',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-wh-03',
      branchName: 'Airport Logistics Hub',
      employeeId: 'emp-105',
      employeeName: 'Lucas Grey',
      productTitle: 'Greek Yogurt 500g Plain',
      reason: ReturnReason.wrongItem,
      quantity: 10.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8722',
      returnDate: DateTime.now().subtract(const Duration(days: 3)),
      status: ReturnStatus.approved,
      remarks: 'Supplier shipped Strawberry flavor instead of Plain.',
      reviewedBy: 'Admin Ops',
      reviewerNotes: 'Return-to-vendor credit issued.',
      reviewedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ReturnItem(
      id: 'RET-007',
      organizationId: 'org-freshgrocer',
      branchId: 'branch-dt-01',
      branchName: 'Downtown Flagship',
      employeeId: 'emp-101',
      employeeName: 'Marcus Vance',
      productTitle: 'Atlantic Salmon Fillets (Fresh)',
      reason: ReturnReason.expired,
      quantity: 6.5,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8710',
      returnDate: DateTime.now().subtract(const Duration(hours: 1)),
      status: ReturnStatus.pending,
      remarks: 'Temperature sensor alert triggered on delivery pallet.',
    ),
  ];

  List<ReturnItem> get returns => List.unmodifiable(_returns);

  void addReturn(ReturnItem item) {
    _returns.insert(0, item);
  }

  ReturnItem updateStatus({
    required String returnId,
    required ReturnStatus status,
    required String reviewerNotes,
    required String reviewerName,
  }) {
    final index = _returns.indexWhere((r) => r.id == returnId);
    if (index == -1) {
      throw Exception('Return item not found: $returnId');
    }
    final updated = _returns[index].copyWith(
      status: status,
      reviewerNotes: reviewerNotes,
      reviewedBy: reviewerName,
      reviewedAt: DateTime.now(),
    );
    _returns[index] = updated;
    return updated;
  }
}
