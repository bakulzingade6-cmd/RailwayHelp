// installation_DB.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:majdur_p/datamodel/install_event_datamodel.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallationDb extends StatelessWidget {
  final String rawJson;
  const InstallationDb({super.key, required this.rawJson});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? jsonData = _parseJson(rawJson);
    if (jsonData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid QR Code Data')),
      );
    }

    // Format data for display using camelCase keys (matches your table)
    final String installedAtFormatted = _formatInstalledAt(jsonData['installedAt']);
    final String locationFormatted = _formatLocation(jsonData['location']);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Installation Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('Client Event ID', _safeString(jsonData, 'clientEventId')),
            _buildDataRow('Type', _safeString(jsonData, 'type', fallback: 'installation')),
            _buildDataRow('QR ID', _safeString(jsonData, 'qrid')),
            _buildDataRow('Asset ID', _safeString(jsonData, 'assetId')),
            _buildDataRow('Installer', _safeString(jsonData, 'installerId')),
            _buildDataRow('Track Section', _safeString(jsonData, 'trackSection')),
            _buildDataRow('Installed At', installedAtFormatted),
            _buildDataRow('Location', locationFormatted),
            _buildDataRow('Notes', _safeString(jsonData, 'notes')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _uploadToSupabase(context, jsonData),
              child: const Text('Confirm & Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _parseJson(String rawJson) {
    try {
      final parsed = json.decode(rawJson);
      if (parsed is Map<String, dynamic>) return parsed;
      return null;
    } catch (e) {
      debugPrint('JSON parse error: $e');
      return null;
    }
  }

  /// Returns a String from map[camelKey] safely; fallback used when missing/empty.
  static String _safeString(Map<String, dynamic>? map, String camelKey, {String fallback = '—'}) {
    if (map == null) return fallback;
    final v = map[camelKey];
    if (v == null) return fallback;
    return v.toString();
  }

  static String _formatInstalledAt(dynamic installedAtValue) {
    if (installedAtValue == null) return '—';
    try {
      DateTime dt;
      if (installedAtValue is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(installedAtValue);
      } else {
        dt = DateTime.parse(installedAtValue.toString());
      }
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return installedAtValue.toString();
    }
  }

  static String _formatLocation(dynamic loc) {
    if (loc == null) return '—';
    try {
      if (loc is Map) {
        final lat = loc['lat']?.toString() ?? '—';
        final lon = loc['lon']?.toString() ?? loc['lng']?.toString() ?? '—';
        return 'Lat: $lat, Lon: $lon';
      }
      return loc.toString();
    } catch (e) {
      return loc.toString();
    }
  }

  Widget _buildDataRow(String label, dynamic value) {
    final valueText = (value == null || (value is String && value.isEmpty)) ? '—' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(valueText)),
        ],
      ),
    );
  }

  Future<void> _uploadToSupabase(BuildContext context, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    if (supabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supabase client not initialized')));
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Parse installedAt (camelCase key)
      final rawInstalled = data['installedAt'];
      DateTime installedAt;
      if (rawInstalled == null) {
        installedAt = DateTime.now();
      } else if (rawInstalled is int) {
        installedAt = DateTime.fromMillisecondsSinceEpoch(rawInstalled);
      } else {
        try {
          installedAt = DateTime.parse(rawInstalled.toString());
        } catch (_) {
          installedAt = DateTime.now();
        }
      }

      // Build model (use camelCase keys to match your table)
      final installEvent = InstallEventDataModel(
        clientEventId: (data['clientEventId'] ?? '').toString(),
        qrId: (data['qrid'] ?? '').toString(),
        assetId: (data['assetId'] ?? '').toString(),
        installerId: (data['installerId'] ?? '').toString(),
        trackSection: (data['trackSection'] ?? '').toString(),
        installedAt: installedAt,
        location: (data['location'] is Map) ? Map<String, dynamic>.from(data['location']) : <String, dynamic>{},
        notes: (data['notes'] ?? '').toString(),
        verifiedBy: user.id,
        verifiedAt: data['verifiedAt'] != null ? DateTime.tryParse(data['verifiedAt'].toString()) : null,
        type: (data['type'] ?? 'installation').toString(),
      );

      // Insert into Supabase (the data model's toMap should produce camelCase keys matching table)
      final response = await InstallEventDataModel.createInstallEvent(installEvent);

      // Remove loading
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (response != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Installation event saved successfully! ID: ${response['id']}')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload completed (no data returned)')));
      }
    } catch (e) {
      // Remove loading
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading: ${e.toString()}')));
      debugPrint('Supabase upload error: $e');
    }
  }
}
