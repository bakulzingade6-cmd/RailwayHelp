// lib/datamodel/install_event_datamodel.dart
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallEventDataModel {
  final String? id;
  final String? clientEventId;
  final String type;
  final String? qrid;
  final String? assetId;
  final String? installerId;
  final String? trackSection;
  final DateTime installedAt;
  final Map<String, dynamic>? location;
  final String? notes;
  final String verifiedBy;
  final DateTime? verifiedAt;

  InstallEventDataModel({
    this.id,
    this.clientEventId,
    required this.type,
    this.qrid,
    this.assetId,
    this.installerId,
    this.trackSection,
    required this.installedAt,
    this.location,
    this.notes,
    required this.verifiedBy,
    this.verifiedAt,
  });

  /// Create from a map (e.g. parsed QR JSON). Accepts many key variants.
  factory InstallEventDataModel.fromMap(Map<String, dynamic> m, {required String currentUserId}) {
    // helper to parse a date value (string or int)
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is DateTime) return v;
      final s = v.toString();
      try {
        return DateTime.parse(s);
      } catch (_) {
        // try common format with space `yyyy-MM-dd HH:mm`
        try {
          return DateTime.parse(s.replaceFirst(' ', 'T'));
        } catch (_) {
          return DateTime.now();
        }
      }
    }

    return InstallEventDataModel(
      id: m['id'] as String?,
      clientEventId: (m['clientEventId'] ?? m['client_event_id']) as String?,
      type: (m['type'] ?? 'installation') as String,
      qrid: (m['qrid'] ?? m['qrId'] ?? m['qr_id']) as String?,
      assetId: (m['asset_id'] ?? m['assetId'] ?? m['assetId']) as String?,
      installerId: (m['installer_id'] ?? m['installerId'] ?? m['installerId']) as String?,
      trackSection: (m['track_section'] ?? m['trackSection'] ?? m['trackSection']) as String?,
      installedAt: parseDate(m['installedAt'] ?? m['installed_at'] ?? m['installed_at_epoch']),
      location: (m['location'] is Map) ? Map<String, dynamic>.from(m['location']) : null,
      notes: (m['notes'] ?? m['note']) as String?,
      verifiedBy: currentUserId,
      verifiedAt: null,
    );
  }

  /// Convert to a Map matching the DB columns.
  /// We include *both* snake_case and camelCase variants where table is ambiguous.
  Map<String, dynamic> toMapForInsert() {
    final map = <String, dynamic>{
      'type': type,
      'qrid': qrid,
      'installer_id': installerId,
      'track_section': trackSection,
      'installedAt': installedAt.toIso8601String(),
      'location': location,
      'notes': notes,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'clientEventId': clientEventId,
      'assetId': assetId,
    };

    // remove nulls (so DB default values can apply)
    map.removeWhere((k, v) => v == null);
    return map;
  }

  /// Insert into Supabase (returns the inserted row map)
  static Future<Map<String, dynamic>> createInstallEvent(InstallEventDataModel ev) async {
    final client = Supabase.instance.client;
    final payload = ev.toMapForInsert();

    // debug: print payload
    // ignore: avoid_print
    print('InstallEvent: inserting payload -> ${jsonEncode(payload)}');

    try {
      final res = await client
          .from('install_events')
          .insert(payload)
          .select()
          .maybeSingle();

      // ignore: avoid_print
      print('InstallEvent: insert response -> $res');
      if (res == null) throw Exception('No response after insert');
      return res as Map<String, dynamic>;
    } catch (e) {
      // include helpful debug message
      // ignore: avoid_print
      print('InstallEvent: insert error -> $e');
      rethrow;
    }
  }
}
