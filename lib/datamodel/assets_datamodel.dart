import 'package:supabase_flutter/supabase_flutter.dart';

class AssetDataModel {
  final String? id;
  final String? name;
  final String? status;
  final String? location;
  final String? section;
  final String? partType;
  final String? vendor;
  final String? batch;
  final int? quantity;
  final String? warranty;
  final DateTime? manufactureDate;
  final DateTime? receivedDate;
  final DateTime? installDate;

  AssetDataModel({
    this.id,
    this.name,
    this.status,
    this.location,
    this.section,
    this.partType,
    this.vendor,
    this.batch,
    this.quantity,
    this.warranty,
    this.manufactureDate,
    this.receivedDate,
    this.installDate,
  });

  // Factory constructor to create an instance from a Map
  factory AssetDataModel.fromMap(Map<String, dynamic> data) {
    return AssetDataModel(
      id: data['id'],
      name: data['name'],
      status: data['status'],
      location: data['location'],
      section: data['section'],
      partType: data['part_type'],
      vendor: data['vendor'],
      batch: data['batch'],
      quantity: data['quantity'],
      warranty: data['warranty'],
      manufactureDate: data['manufacture_date'] != null
          ? DateTime.parse(data['manufacture_date'])
          : null,
      receivedDate: data['received_date'] != null
          ? DateTime.parse(data['received_date'])
          : null,
      installDate: data['install_date'] != null
          ? DateTime.parse(data['install_date'])
          : null,
    );
  }

  // Method to convert instance back to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'location': location,
      'section': section,
      'part_type': partType,
      'vendor': vendor,
      'batch': batch,
      'quantity': quantity,
      'warranty': warranty,
      'manufacture_date': manufactureDate?.toIso8601String(),
      'received_date': receivedDate?.toIso8601String(),
      'install_date': installDate?.toIso8601String(),
    };
  }

  // Create a new asset entry in the Supabase database
  static Future<void> createAsset(AssetDataModel asset) async {
    final response = await Supabase.instance.client
        .from('assets')
        .insert(asset.toMap());
    if (response.error != null) {
      throw Exception('Failed to create asset: ${response.error!.message}');
    }
  }
}
