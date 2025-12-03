import 'package:supabase_flutter/supabase_flutter.dart';

class AlertDataModel {
  final String? id;
  final String? message;
  final String? severity;
  final DateTime? date;
  final bool? active;

  AlertDataModel({
    this.id,
    this.message,
    this.severity,
    this.date,
    this.active,
  });

  // Factory constructor to create an instance from a Map
  factory AlertDataModel.fromMap(Map<String, dynamic> data) {
    return AlertDataModel(
      id: data['id'],
      message: data['message'],
      severity: data['severity'],
      date: data['date'] != null ? DateTime.parse(data['date']) : null,
      active: data['active'],
    );
  }

  // Method to convert instance back to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'severity': severity,
      'date': date?.toIso8601String(),
      'active': active,
    };
  }

  // Create a new alert entry in the Supabase database
  static Future<void> createAlert(AlertDataModel alert) async {
    final response = await Supabase.instance.client
        .from('alerts')
        .insert(alert.toMap());
    if (response.error != null) {
      throw Exception('Failed to create alert: ${response.error!.message}');
    }
  }
}
