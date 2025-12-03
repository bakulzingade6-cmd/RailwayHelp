import 'package:supabase_flutter/supabase_flutter.dart';

class EventDataModel {
  final String? id;
  final String? type;
  final DateTime? date;
  final String? description;
  final String? assetId;

  EventDataModel({
    this.id,
    this.type,
    this.date,
    this.description,
    this.assetId,
  });

  // Factory constructor to create an instance from a Map
  factory EventDataModel.fromMap(Map<String, dynamic> data) {
    return EventDataModel(
      id: data['id'],
      type: data['type'],
      date: data['date'] != null ? DateTime.parse(data['date']) : null,
      description: data['description'],
      assetId: data['asset_id'],
    );
  }

  // Method to convert instance back to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date?.toIso8601String(),
      'description': description,
      'asset_id': assetId,
    };
  }

  // Create a new event entry in the Supabase database
  static Future<void> createEvent(EventDataModel event) async {
    final response = await Supabase.instance.client
        .from('events')
        .insert(event.toMap());
    if (response.error != null) {
      throw Exception('Failed to create event: ${response.error!.message}');
    }
  }
}
