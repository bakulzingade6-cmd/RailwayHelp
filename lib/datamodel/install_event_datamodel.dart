// lib/datamodel/install_event_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallEventDataModel {
  final String? id;
  final String? assetId;
  final String? installedBy;
  final Map<String, dynamic>? location;
  final DateTime installationDate;
  final String status;

  InstallEventDataModel({
    this.id,
    this.assetId,
    this.installedBy,
    this.location,
    required this.installationDate,
    required this.status,
  });

  factory InstallEventDataModel.fromMap(Map<String, dynamic> m, {required String currentUserId}) {

    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is DateTime) return v;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        try {
          return DateTime.parse(s.replaceFirst(' ', 'T'));
        } catch (_) {
          return DateTime.now();
        }
      }
    }

    return InstallEventDataModel(
      id: m['id'] as String?,
      assetId: (m['asset_id'] ?? m['assetId'] ?? m['id']) as String?,
      installedBy: (m['installed_by'] ?? m['installer_id'] ?? currentUserId) as String?,
      location: (m['location'] is Map)
          ? Map<String, dynamic>.from(m['location'])
          : (m['loc'] is Map ? Map<String, dynamic>.from(m['loc']) : null),
      installationDate: parseDate(m['installation_date'] ?? m['install_date'] ?? m['created_at']),
      status: (m['status'] ?? 'Installed') as String,
    );
  }

  Map<String, dynamic> toMapForInsert() {
    final map = <String, dynamic>{
      'asset_id': assetId,
      'installed_by': installedBy,
      'location': location,
      'installation_date': installationDate.toIso8601String(),
      'status': status,
    };
    map.removeWhere((k, v) => v == null);
    return map;
  }

  static Future<Map<String, dynamic>> createInstallEvent(InstallEventDataModel ev) async {
    final client = Supabase.instance.client;
    final payload = ev.toMapForInsert();
    print('InstallEvent: inserting payload -> ${jsonEncode(payload)}');
    try {
      final res = await client
          .from('install_events')
          .insert(payload)
          .select()
          .maybeSingle();
      print('InstallEvent: insert response -> $res');

      if (res == null) {
        return {'status': 'success', 'message': 'Inserted (No data returned)'};
      }

      return res as Map<String, dynamic>;
    } catch (e) {
      print('InstallEvent: insert error -> $e');
      rethrow;
    }
  }
}
