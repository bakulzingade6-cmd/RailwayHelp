import 'package:supabase_flutter/supabase_flutter.dart';

class InstallEventDataModel {
  final String? id;
  final String clientEventId;
  final String qrId;
  final String? assetId;
  final String installerId;
  final String trackSection;
  final DateTime installedAt;
  final Map<String, dynamic> location;
  final String? notes;
  final String verifiedBy;
  final DateTime? verifiedAt;
  final String type;

  InstallEventDataModel({
    this.id,
    required this.clientEventId,
    required this.qrId,
    this.assetId,
    required this.installerId,
    required this.trackSection,
    required this.installedAt,
    required this.location,
    this.notes,
    required this.verifiedBy,
    this.verifiedAt,
    required this.type,
  });

  /// CREATE from DB map
  factory InstallEventDataModel.fromMap(Map<String, dynamic> data) {
    return InstallEventDataModel(
      id: data['id'],
      clientEventId: data['clientEventId'] ?? data['client_event_id'] ?? '',
      qrId: data['qrId'] ?? data['qrid'] ?? '',
      assetId: data['assetId'] ?? data['asset_id'],
      installerId: data['installerId'] ?? data['installer_id'] ?? '',
      trackSection: data['trackSection'] ?? data['track_section'] ?? '',
      installedAt: data['installedAt'] != null
          ? DateTime.parse(data['installedAt'])
          : DateTime.now(),
      location: data['location'] ?? {},
      notes: data['notes'],
      verifiedBy: data['verifiedBy'] ?? data['verified_by'] ?? '',
      verifiedAt: data['verifiedAt'] != null
          ? DateTime.parse(data['verifiedAt'])
          : null,
      type: data['type'] ?? '',
    );
  }

  /// Convert to map for Supabase insert
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      'clientEventId': clientEventId,
      'qrid': qrId,
      'installerId': installerId,
      'trackSection': trackSection,
      'installedAt': installedAt.toIso8601String(),
      'location': location,
      'notes': notes,
      'verifiedBy': verifiedBy,
      'type': type,
    };

    if (assetId != null) map['asset_id'] = assetId;
    if (verifiedAt != null) map['verifiedAt'] = verifiedAt!.toIso8601String();

    // Only add id for update
    if (id != null) map['id'] = id;

    return map;
  }

  /// Insert new event
  static Future<Map<String, dynamic>> createInstallEvent(
      InstallEventDataModel installEvent) async {
    try {
      final response = await Supabase.instance.client
          .from('install_events')
          .insert(installEvent.toMap())
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Insert returned null');
      }
      return response;
    } catch (e) {
      throw Exception('Failed to create install event: $e');
    }
  }

  /// Update existing
  static Future<Map<String, dynamic>> updateInstallEvent(
      InstallEventDataModel installEvent) async {
    if (installEvent.id == null) {
      throw Exception('Cannot update without ID');
    }

    try {
      final response = await Supabase.instance.client
          .from('install_events')
          .update(installEvent.toMap())
          .eq('id', installEvent.id!)
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Update returned null');
      }
      return response;
    } catch (e) {
      throw Exception('Failed to update install event: $e');
    }
  }
}
