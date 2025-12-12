import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemovalEventDataModel {
  final String? id;
  final String assetId;
  final String partName;
  final String removedBy; 
  final DateTime removalDate;

  RemovalEventDataModel({
    this.id,
    required this.assetId,
    required this.partName,
    required this.removedBy,
    DateTime? removalDate,
  }) : removalDate = removalDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'asset_id': assetId,
      'part_name': partName,
      'removed_by': removedBy,
      'removal_date': removalDate.toIso8601String(),
    }..removeWhere((k, v) => v == null);
  }

  /// Calls delete_asset_and_log RPC
  static Future<Map<String, dynamic>> createRemovalEvent(RemovalEventDataModel ev) async {
    final client = Supabase.instance.client;

    dynamic response;

    try {
      response = await client.rpc('delete_asset_and_log', params: {
        'p_asset_id': ev.assetId,
        'p_part_name': ev.partName,
        'p_removed_by': ev.removedBy,
      });
    } catch (e) {
      throw Exception("RPC call failed: $e");
    }

    // If null
    if (response == null) {
      throw Exception("RPC returned no data");
    }

    // If Map
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    // If List containing 1 Map
    if (response is List && response.isNotEmpty && response.first is Map) {
      return Map<String, dynamic>.from(response.first);
    }

    // If string JSON
    if (response is String) {
      try {
        final decoded = json.decode(response);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        if (decoded is List && decoded.first is Map) {
          return Map<String, dynamic>.from(decoded.first);
        }
        return {"result": decoded};
      } catch (_) {
        throw Exception("RPC returned non-JSON string");
      }
    }

    // Unknown return type
    return {"result": response};
  }
}
