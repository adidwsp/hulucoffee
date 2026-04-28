import 'dart:convert';
import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String orderNumber;
  final DateTime createdAt;
  final String itemsJson; // JSON-encoded list of item summaries
  final double total;
  final int itemCount;
  final String paymentMethod;

  const Transaction({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.itemsJson,
    required this.total,
    required this.itemCount,
    this.paymentMethod = 'QRIS',
  });

  List<Map<String, dynamic>> get items =>
      List<Map<String, dynamic>>.from(jsonDecode(itemsJson));

  @override
  List<Object?> get props =>
      [id, orderNumber, createdAt, itemsJson, total, itemCount, paymentMethod];

  Map<String, dynamic> toMap() => {
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'itemsJson': itemsJson,
        'total': total,
        'itemCount': itemCount,
        'paymentMethod': paymentMethod,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'] as String,
        orderNumber: map['orderNumber'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        itemsJson: map['itemsJson'] as String,
        total: (map['total'] as num).toDouble(),
        itemCount: map['itemCount'] as int,
        paymentMethod: map['paymentMethod'] as String? ?? 'QRIS',
      );
}
