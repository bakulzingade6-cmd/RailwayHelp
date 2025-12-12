// lib/datamodel/inspections_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InspectionDataModel {
  final String? id;
  final DateTime? inspectionDate;
  final String inspectedBy;
  final String assetId;
  final String partStatus;
  final String? inspectDetail;
  final int photosCount;
  final String severity;

  InspectionDataModel({
    this.id,
    this.inspectionDate,
    required this.inspectedBy,
    required this.assetId,
    required this.partStatus,
    this.inspectDetail,
    this.photosCount = 0,
    required this.severity,
  });

  factory InspectionDataModel.fromMap(Map<String, dynamic> m) {
    return InspectionDataModel(
      id: m['id'] as String?,
      inspectionDate: m['inspection_date'] != null ? DateTime.tryParse(m['inspection_date'].toString()) : null,
      inspectedBy: (m['inspected_by'] ?? '') as String,
      assetId: (m['asset_id'] ?? m['assetId'] ?? '') as String,
      partStatus: (m['part_status'] ?? '') as String,
      inspectDetail: m['inspect_detail'] as String?,
      photosCount: m['photos_count'] != null ? (m['photos_count'] as num).toInt() : 0,
      severity: (m['severity'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inspection_date': inspectionDate?.toIso8601String().split('T').first,
      'inspected_by': inspectedBy,
      'asset_id': assetId,
      'part_status': partStatus,
      'inspect_detail': inspectDetail,
      'photos_count': photosCount,
      'severity': severity,
    };
  }

  static Future<Map<String, dynamic>> createInspection(InspectionDataModel inspection) async {
    try {
      final payload = inspection.toMap();
      print('Inserting inspection payload: ${jsonEncode(payload)}');
      final resp = await Supabase.instance.client
          .from('inspections')
          .insert(payload)
          .select()
          .maybeSingle();
      if (resp == null) throw Exception('No response after insert');
      return resp as Map<String, dynamic>;
    } catch (e) {
      print('createInspection error: $e');
      throw Exception('Failed to create inspection: $e');
    }
  }
}
