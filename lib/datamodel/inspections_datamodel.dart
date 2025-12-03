// lib/datamodel/inspection_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionDataModel {
  final String? id;
  final DateTime? date;
  final String inspector;
  final String assetId;
  final String status; // may contain UI label; will be normalized before insert
  final String? notes;
  final String? vendor;
  final String? severity; // may contain UI label; will be normalized before insert
  final int photosCount;
  final DateTime? createdAt;

  InspectionDataModel({
    this.id,
    this.date,
    required this.inspector,
    required this.assetId,
    required this.status,
    this.notes,
    this.vendor,
    this.severity,
    this.photosCount = 0,
    this.createdAt,
  });

  factory InspectionDataModel.fromMap(Map<String, dynamic> m) {
    return InspectionDataModel(
      id: m['id'] as String?,
      date: m['date'] != null ? DateTime.tryParse(m['date'].toString()) : null,
      inspector: (m['inspector'] ?? '') as String,
      assetId: (m['asset_id'] ?? m['assetId'] ?? '') as String,
      status: (m['status'] ?? '') as String,
      notes: m['notes'] as String?,
      vendor: m['vendor'] as String?,
      severity: m['severity'] as String?,
      photosCount: m['photos_count'] != null ? (m['photos_count'] as num).toInt() : 0,
      createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) : null,
    );
  }

  /// Normalize UI labels to DB-safe values for status.
  /// Accepts either already-normalized values or UI labels.
  static String normalizeStatus(String uiStatus) {
    final s = uiStatus.trim().toLowerCase();
    if (s == 'good' || s == 'ok') return 'good';
    if (s == 'needs repair' || s == 'needs_repair' || s.contains('needs') && s.contains('repair')) return 'needs_repair';
    if (s == 'critical') return 'critical';
    // fallback: convert spaces to underscores and lowercase
    return s.replaceAll(RegExp(r'\s+'), '_');
  }

  /// Normalize severity similarly.
  static String? normalizeSeverity(String? uiSeverity) {
    if (uiSeverity == null) return null;
    final s = uiSeverity.trim().toLowerCase();
    if (s.startsWith('l')) return 'low';
    if (s.startsWith('m')) return 'medium';
    if (s.startsWith('h')) return 'high';
    // fallback: return lowercased value
    return s.replaceAll(RegExp(r'\s+'), '_');
  }

  /// Convert model to map ready for DB insert (snake_case column names)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      // date column in your table is 'date' (not timestamp), keep YYYY-MM-DD
      'date': date != null ? date!.toIso8601String().split('T').first : null,
      'inspector': inspector,
      'asset_id': assetId,
      // normalize before sending — this ensures DB check constraints match
      'status': normalizeStatus(status),
      'notes': notes,
      'vendor': vendor,
      'severity': normalizeSeverity(severity),
      'photos_count': photosCount,
    };

    // Remove nulls so DB defaults (created_at, etc.) work
    map.removeWhere((k, v) => v == null);
    return map;
  }

  /// Insert into Supabase and return created row.
  static Future<Map<String, dynamic>> createInspection(InspectionDataModel inspection) async {
    try {
      final payload = inspection.toMap();

      // Debug print for verification — remove in production if desired.
      // ignore: avoid_print
      print('Inserting inspection payload: ${jsonEncode(payload)}');

      final resp = await Supabase.instance.client
          .from('inspections')
          .insert(payload)
          .select()
          .maybeSingle();

      if (resp == null) throw Exception('No response after insert');
      return resp as Map<String, dynamic>;
    } catch (e) {
      // Better error visibility for DB errors. Supabase returns detailed error strings,
      // so we print and rethrow a wrapped exception.
      // ignore: avoid_print
      print('createInspection error: $e');
      throw Exception('Failed to create inspection: $e');
    }
  }
}
