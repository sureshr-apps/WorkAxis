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
  rotten,
  wrongItem,
  customerReturned,
  expired,
  other;

  /// Parses the stored reason (the enum name; case-insensitive). Unknown
  /// legacy values map to [ReturnReason.other], which is a real category.
  static ReturnReason parse(String? raw) {
    final value = raw?.trim().toLowerCase();
    for (final reason in ReturnReason.values) {
      if (reason.name.toLowerCase() == value) return reason;
    }
    if (value == 'rotten') return ReturnReason.rotten;
    if (value == 'wrong item' || value == 'wrong item supplied') {
      return ReturnReason.wrongItem;
    }
    if (value == 'customer return' || value == 'customer returned') {
      return ReturnReason.customerReturned;
    }
    if (value == 'damaged product' || value == 'damaged') {
      return ReturnReason.damaged;
    }
    if (value == 'expired stock' || value == 'expired') {
      return ReturnReason.expired;
    }
    return ReturnReason.other;
  }

  /// Full descriptive label (kept for reporting backwards-compatibility).
  String get label {
    switch (this) {
      case ReturnReason.damaged:
        return 'Damaged Product';
      case ReturnReason.rotten:
        return 'Rotten';
      case ReturnReason.wrongItem:
        return 'Wrong Item Supplied';
      case ReturnReason.customerReturned:
        return 'Customer Return';
      case ReturnReason.expired:
        return 'Expired Stock';
      case ReturnReason.other:
        return 'Other Reason';
    }
  }

  /// Clean user-facing title.
  String get displayName {
    switch (this) {
      case ReturnReason.damaged:
        return 'Damaged';
      case ReturnReason.rotten:
        return 'Rotten';
      case ReturnReason.wrongItem:
        return 'Wrong Item';
      case ReturnReason.customerReturned:
        return 'Customer Returned';
      case ReturnReason.expired:
        return 'Expired';
      case ReturnReason.other:
        return 'Other';
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
  final String? billNumber;
  final String invoiceNumber;
  final DateTime returnDate;
  final String productTitle;
  final ReturnReason reason;
  final double quantity;
  final String unit;
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
    this.billNumber,
    required this.invoiceNumber,
    required this.returnDate,
    required this.productTitle,
    required this.reason,
    required this.quantity,
    required this.unit,
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
    String? billNumber,
    String? invoiceNumber,
    DateTime? returnDate,
    String? productTitle,
    ReturnReason? reason,
    double? quantity,
    String? unit,
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
      billNumber: billNumber ?? this.billNumber,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      returnDate: returnDate ?? this.returnDate,
      productTitle: productTitle ?? this.productTitle,
      reason: reason ?? this.reason,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
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
  final String? branchId;
  final String? branchName;
  final String? billNumber;
  final String invoiceNumber;
  final DateTime? returnDate;
  final String productTitle;
  final double quantity;
  final String unit;
  final ReturnReason reason;
  final String? billImageUrl;
  final String? remarks;

  const CreateReturnInput({
    this.branchId,
    this.branchName,
    this.billNumber,
    required this.invoiceNumber,
    this.returnDate,
    required this.productTitle,
    required this.quantity,
    this.unit = 'units',
    required this.reason,
    this.billImageUrl,
    this.remarks,
  });

  CreateReturnBatchInput toBatch() => CreateReturnBatchInput(
    branchId: branchId,
    branchName: branchName,
    billNumber: billNumber,
    invoiceNumber: invoiceNumber,
    returnDate: returnDate,
    billImageUrl: billImageUrl,
    remarks: remarks,
    items: [
      ReturnLineItemInput(
        productTitle: productTitle,
        quantity: quantity,
        unit: unit,
        reason: reason,
        remarks: remarks,
      ),
    ],
  );
}

class ReturnLineItemInput {
  final String productTitle;
  final double quantity;
  final String unit;
  final ReturnReason reason;
  final String? remarks;

  const ReturnLineItemInput({
    required this.productTitle,
    required this.quantity,
    this.unit = 'units',
    required this.reason,
    this.remarks,
  });
}

class CreateReturnBatchInput {
  final String? branchId;
  final String? branchName;
  final String? billNumber;
  final String invoiceNumber;
  final DateTime? returnDate;
  final String? billImageUrl;
  final String? remarks;
  final List<ReturnLineItemInput> items;

  const CreateReturnBatchInput({
    this.branchId,
    this.branchName,
    this.billNumber,
    required this.invoiceNumber,
    this.returnDate,
    this.billImageUrl,
    this.remarks,
    required this.items,
  });

  List<CreateReturnInput> toCreateReturnInputs() {
    return items.map((item) {
      final combinedRemarks = [
        if (remarks != null && remarks!.trim().isNotEmpty) remarks!.trim(),
        if (item.remarks != null && item.remarks!.trim().isNotEmpty)
          item.remarks!.trim(),
      ].join(' - ');

      return CreateReturnInput(
        branchId: branchId,
        branchName: branchName,
        billNumber: billNumber,
        invoiceNumber: invoiceNumber,
        returnDate: returnDate,
        productTitle: item.productTitle,
        quantity: item.quantity,
        unit: item.unit,
        reason: item.reason,
        billImageUrl: billImageUrl,
        remarks: combinedRemarks.isEmpty ? null : combinedRemarks,
      );
    }).toList();
  }
}
