// lib/datamodel/removal_event_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemovalEventDataModel {
  final String? id;
  final String assetId;
  final String removedBy; // user id or name
  final String? notes;
  final DateTime removedAt;

  RemovalEventDataModel({
    this.id,
    required this.assetId,
    required this.removedBy,
    this.notes,
    DateTime? removedAt,
  }) : removedAt = removedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'asset_id': assetId,
      'removed_by': removedBy,
      'notes': notes,
      'removed_at': removedAt.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }

  static Future<Map<String, dynamic>?> createRemovalEvent(RemovalEventDataModel ev) async {
    final client = Supabase.instance.client;
    final res = await client.from('part_removals').insert(ev.toMap()).select().maybeSingle();
    return res as Map<String, dynamic>?;
  }
}
