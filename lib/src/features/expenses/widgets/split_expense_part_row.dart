import 'package:flutter/material.dart';

import '../../../core/formatters.dart';

class SplitPartRow {
  SplitPartRow({this.categoryId, int amount = 0})
      : controller = TextEditingController(
            text: amount > 0 ? Money.groupDigits(amount) : '');

  String? categoryId;
  final TextEditingController controller;

  int get amount => Money.parse(controller.text) ?? 0;
}
