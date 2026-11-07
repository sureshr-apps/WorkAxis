enum ReturnStatus {
  pending,
  approved,
  rejected;

  /// Parses the server's status vocabulary (`pending`, `approved`,
  /// `rejected`; case-insensitive). Returns null for anything else so callers
  /// never silently treat an unknown status as another one.
  static ReturnStatus? tryParse(String? raw) {
    final value = raw?.trim().toLowerCase();
    for (final status in ReturnStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  String get label {
    switch (this) {
      case ReturnStatus.pending:
        return 'Pending';
      case ReturnStatus.approved:
        return 'Approved';
      case ReturnStatus.rejected:
        return 'Rejected';
    }
  }
}

enum ReturnReason {
  damaged,
  expired,
  wrongItem,
  customerReturned,
  other;

  /// Parses the stored reason (the enum name; case-insensitive). Unknown
  /// legacy values map to [ReturnReason.other], which is a real category.
  static ReturnReason parse(String? raw) {
    final value = raw?.trim().toLowerCase();
    for (final reason in ReturnReason.values) {
      if (reason.name.toLowerCase() == value) return reason;
    }
    return ReturnReason.other;
  }

  String get label {
    switch (this) {
      case ReturnReason.damaged:
        return 'Damaged Product';
      case ReturnReason.expired:
        return 'Expired Stock';
      case ReturnReason.wrongItem:
        return 'Wrong Item Supplied';
      case ReturnReason.customerReturned:
        return 'Customer Return';
      case ReturnReason.other:
        return 'Other Reason';
    }
  }
}

class ReturnItem {
  final String id;
  final String organizationId;
  final String branchId;
  final String branchName;
  final String employeeId;
  final String employeeName;
  final String productTitle;
  final ReturnReason reason;
  final double quantity;
  final String unit;
  final String invoiceNumber;
  final DateTime returnDate;
  final ReturnStatus status;
  final String? billImageUrl;
  final String? remarks;
  final String? reviewerNotes;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const ReturnItem({
    required this.id,
    required this.organizationId,
    required this.branchId,
    required this.branchName,
    required this.employeeId,
    required this.employeeName,
    required this.productTitle,
    required this.reason,
    required this.quantity,
    required this.unit,
    required this.invoiceNumber,
    required this.returnDate,
    required this.status,
    this.billImageUrl,
    this.remarks,
    this.reviewerNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  ReturnItem copyWith({
    String? id,
    String? organizationId,
    String? branchId,
    String? branchName,
    String? employeeId,
    String? employeeName,
    String? productTitle,
    ReturnReason? reason,
    double? quantity,
    String? unit,
    String? invoiceNumber,
    DateTime? returnDate,
    ReturnStatus? status,
    String? billImageUrl,
    String? remarks,
    String? reviewerNotes,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return ReturnItem(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      productTitle: productTitle ?? this.productTitle,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      returnDate: returnDate ?? this.returnDate,
      status: status ?? this.status,
      billImageUrl: billImageUrl ?? this.billImageUrl,
      remarks: remarks ?? this.remarks,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
    );
  }
}

class CreateReturnInput {
  final String productTitle;
  final ReturnReason reason;
  final double quantity;
  final String unit;
  final String invoiceNumber;
  final String? billImageUrl;
  final String? remarks;

  const CreateReturnInput({
    required this.productTitle,
    required this.reason,
    required this.quantity,
    required this.unit,
    required this.invoiceNumber,
    this.billImageUrl,
    this.remarks,
  });
}
