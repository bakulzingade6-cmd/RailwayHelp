// lib/datamodel/inspection_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionDataModel {
  final String? id;
  final DateTime? date;
  final String inspector;
  final String assetId;
  final String status; // UI label — will be mapped to DB value
  final String? notes;
  final String? vendor;
  final String? severity; // UI label — will be mapped to DB value
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

  /// Map UI labels to DB-allowed 'status' values.
  /// DB expects: 'Pass', 'Fail', 'Completed'
  static String mapStatusToDb(String uiStatus) {
    final s = uiStatus.trim().toLowerCase();

    if (s == 'good' || s == 'pass' || s == 'ok') return 'Pass';
    if (s.contains('needs') && s.contains('repair')) return 'Fail';
    if (s == 'needs repair' || s == 'needs_repair' || s == 'needsrepair') return 'Fail';
    if (s == 'critical' || s == 'fail' || s == 'failed') return 'Fail';
    if (s == 'completed') return 'Completed';

    // Fallback: if the UI already sent a DB value, normalize its case
    final capitalized = uiStatus.trim();
    if (['Pass', 'Fail', 'Completed'].contains(capitalized)) return capitalized;
    // Last resort: return 'Fail' to avoid DB rejection (safer than unknown)
    return 'Fail';
  }

  /// Map UI severity to DB format: 'Low', 'Medium', 'High'
  static String? mapSeverityToDb(String? uiSeverity) {
    if (uiSeverity == null) return null;
    final s = uiSeverity.trim().toLowerCase();
    if (s.startsWith('l')) return 'Low';
    if (s.startsWith('m')) return 'Medium';
    if (s.startsWith('h')) return 'High';
    // If already DB value (maybe user typed), normalize casing
    final cap = uiSeverity.trim();
    if (['Low', 'Medium', 'High'].contains(cap)) return cap;
    // Fallback: capitalize first letter
    return uiSeverity.trim()[0].toUpperCase() + uiSeverity.trim().substring(1).toLowerCase();
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'date': date != null ? date!.toIso8601String().split('T').first : null,
      'inspector': inspector,
      'asset_id': assetId,
      // Map UI -> DB expected values
      'status': mapStatusToDb(status),
      'notes': notes,
      'vendor': vendor,
      'severity': mapSeverityToDb(severity),
      'photos_count': photosCount,
    };

    map.removeWhere((k, v) => v == null);
    return map;
  }

  static Future<Map<String, dynamic>> createInspection(InspectionDataModel inspection) async {
    try {
      final payload = inspection.toMap();
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
      // ignore: avoid_print
      print('createInspection error: $e');
      throw Exception('Failed to create inspection: $e');
    }
  }
}
