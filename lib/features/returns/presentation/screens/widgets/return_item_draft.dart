import 'package:flutter/material.dart';
import 'package:workaxis/features/returns/domain/models/return_item.dart';

/// Interactive draft model for an individual item row being returned from a bill.
class ReturnItemDraft {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController remarksController;
  ReturnReason reason;
  String unit;
  String? productError;
  String? quantityError;

  ReturnItemDraft({
    String product = '',
    String quantity = '1',
    this.reason = ReturnReason.damaged,
    this.unit = 'kg',
    String remarks = '',
  }) : productController = TextEditingController(text: product),
       quantityController = TextEditingController(text: quantity),
       remarksController = TextEditingController(text: remarks);

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    remarksController.dispose();
  }
}
