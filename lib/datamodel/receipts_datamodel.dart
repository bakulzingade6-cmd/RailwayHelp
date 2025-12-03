import 'package:supabase_flutter/supabase_flutter.dart';

class ReceiptDataModel {
  final String? id;
  final DateTime? date;
  final List<String>? items;
  final double? value;

  ReceiptDataModel({
    this.id,
    this.date,
    this.items,
    this.value,
  });

  // Factory constructor to create an instance from a Map
  factory ReceiptDataModel.fromMap(Map<String, dynamic> data) {
    return ReceiptDataModel(
      id: data['id'],
      date: data['date'] != null ? DateTime.parse(data['date']) : null,
      items: data['items'] != null ? List<String>.from(data['items']) : null,
      value: data['value'] != null ? (data['value'] as num).toDouble() : null,
    );
  }

  // Method to convert instance back to a Map
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date?.toIso8601String(),
      'items': items,
      'value': value,
    };

    // Only include 'id' if it's not null
    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // Create a new receipt entry in the Supabase database
  static Future<Map<String, dynamic>?> createReceipt(ReceiptDataModel receipt) async {
    try {
      final response = await Supabase.instance.client
          .from('receipts')
          .insert(receipt.toMap())
          .select()
          .maybeSingle();

      if (response is Map<String, dynamic>) {
        return response;
      }

      return null;
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }
}
