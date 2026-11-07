import 'package:workaxis/core/errors/app_exceptions.dart';
import 'package:workaxis/core/time/clock.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

class MockReturnsDataSource {
  MockReturnsDataSource({Now? now}) : _now = now ?? systemNow {
    _returns.addAll(_seed());
  }

  final Now _now;
  final List<ReturnItem> _returns = [];

  List<ReturnItem> _seed() => [
    ReturnItem(
      id: 'RET-001',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-01',
      employeeName: 'Sarah Connor',
      productTitle: 'Organic Fuji Apples (Batch #FA-902)',
      reason: ReturnReason.damaged,
      quantity: 12.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8812',
      returnDate: _now().subtract(const Duration(hours: 3)),
      status: ReturnStatus.pending,
      remarks: 'Bruised during cold-chain transfer from primary distribution center.',
    ),
    ReturnItem(
      id: 'RET-002',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-02',
      employeeName: 'Alex Chen',
      productTitle: 'Fresh Whole Milk 1L (Crate 4)',
      reason: ReturnReason.expired,
      quantity: 24.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8809',
      returnDate: _now().subtract(const Duration(hours: 5)),
      status: ReturnStatus.pending,
      remarks: 'Product reached best-before date prior to display stocking.',
    ),
    ReturnItem(
      id: 'RET-003',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-01',
      employeeName: 'Sarah Connor',
      productTitle: 'Valencia Navel Oranges (Box #VO-114)',
      reason: ReturnReason.customerReturned,
      quantity: 18.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8790',
      returnDate: _now().subtract(const Duration(days: 1)),
      status: ReturnStatus.approved,
      remarks: 'Customer returned sealed crate with proof of purchase.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes:
          'Verified receipt and crate condition. Store credit approved.',
      reviewedAt: _now().subtract(const Duration(hours: 18)),
    ),
    ReturnItem(
      id: 'RET-004',
      organizationId: 'org-acme',
      branchId: 'br-02',
      branchName: 'Westside Hub',
      employeeId: 'user-emp-03',
      employeeName: 'Priya Shah',
      productTitle: 'Imported Hass Avocados (Case #HA-40)',
      reason: ReturnReason.damaged,
      quantity: 8.0,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8765',
      returnDate: _now().subtract(const Duration(days: 2)),
      status: ReturnStatus.rejected,
      remarks: 'Overripe condition discovered after customer delivery.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes: 'Exceeded 48-hour return window for perishable category.',
      reviewedAt: _now().subtract(const Duration(days: 1)),
    ),
    ReturnItem(
      id: 'RET-005',
      organizationId: 'org-acme',
      branchId: 'br-02',
      branchName: 'Westside Hub',
      employeeId: 'user-emp-04',
      employeeName: 'Daniel Kim',
      productTitle: 'Artisan Sourdough Loaves',
      reason: ReturnReason.expired,
      quantity: 15.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8740',
      returnDate: _now().subtract(const Duration(days: 2)),
      status: ReturnStatus.approved,
      remarks: 'Bakery surplus past shelf-life threshold.',
      reviewedBy: 'Elena Rostova',
      reviewerNotes: 'Write-off verified for compost diversion.',
      reviewedAt: _now().subtract(const Duration(days: 1)),
    ),
    ReturnItem(
      id: 'RET-006',
      organizationId: 'org-acme',
      branchId: 'br-04',
      branchName: 'East Bay Outlet',
      employeeId: 'user-emp-07',
      employeeName: 'Lena Park',
      productTitle: 'Greek Yogurt 500g Plain',
      reason: ReturnReason.wrongItem,
      quantity: 10.0,
      unit: 'units',
      invoiceNumber: 'INV-2026-8722',
      returnDate: _now().subtract(const Duration(days: 3)),
      status: ReturnStatus.approved,
      remarks: 'Supplier shipped Strawberry flavor instead of Plain.',
      reviewedBy: 'Admin Ops',
      reviewerNotes: 'Return-to-vendor credit issued.',
      reviewedAt: _now().subtract(const Duration(days: 2)),
    ),
    ReturnItem(
      id: 'RET-007',
      organizationId: 'org-acme',
      branchId: 'br-01',
      branchName: 'Downtown Flagship',
      employeeId: 'user-emp-01',
      employeeName: 'Sarah Connor',
      productTitle: 'Atlantic Salmon Fillets (Fresh)',
      reason: ReturnReason.expired,
      quantity: 6.5,
      unit: 'kg',
      invoiceNumber: 'INV-2026-8710',
      returnDate: _now().subtract(const Duration(hours: 1)),
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
    String? reviewerNotes,
    required String reviewerName,
  }) {
    final index = _returns.indexWhere((r) => r.id == returnId);
    if (index == -1) {
      throw const NotFoundException('Return not found.');
    }
    final updated = _returns[index].copyWith(
      status: status,
      reviewerNotes: reviewerNotes,
      reviewedBy: reviewerName,
      reviewedAt: _now(),
    );
    _returns[index] = updated;
    return updated;
  }
}
