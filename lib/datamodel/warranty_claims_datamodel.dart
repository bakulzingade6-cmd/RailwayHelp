import 'package:supabase_flutter/supabase_flutter.dart';

class WarrantyClaimDataModel {
  final String? id;
  final DateTime? date;
  final String? assetId;
  final String? vendor;
  final String? issue;
  final String? status;
  final String? vendorResponse;

  WarrantyClaimDataModel({
    this.id,
    this.date,
    this.assetId,
    this.vendor,
    this.issue,
    this.status,
    this.vendorResponse,
  });

  // Factory constructor to create an instance from a Map
  factory WarrantyClaimDataModel.fromMap(Map<String, dynamic> data) {
    return WarrantyClaimDataModel(
      id: data['id'],
      date: data['date'] != null ? DateTime.parse(data['date']) : null,
      assetId: data['asset_id'],
      vendor: data['vendor'],
      issue: data['issue'],
      status: data['status'],
      vendorResponse: data['vendor_response'],
    );
  }

  // Method to convert instance back to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'asset_id': assetId,
      'vendor': vendor,
      'issue': issue,
      'status': status,
      'vendor_response': vendorResponse,
    };
  }

  // Create a new warranty claim entry in the Supabase database
  static Future<void> createWarrantyClaim(WarrantyClaimDataModel claim) async {
    final response = await Supabase.instance.client
        .from('warranty_claims')
        .insert(claim.toMap());
    if (response.error != null) {
      throw Exception('Failed to create warranty claim: ${response.error!.message}');
    }
  }
}
