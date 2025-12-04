// lib/pages/installation_DB.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:majdur_p/datamodel/install_event_datamodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallationDb extends StatelessWidget {
  final String rawJson;
  const InstallationDb({super.key, required this.rawJson});

  Map<String, dynamic>? _parseJson(String raw) {
    try {
      final parsed = json.decode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('InstallationDb: JSON parse error -> $e');
      return null;
    }
  }

  static String _formatInstalledAt(dynamic v) {
    if (v == null) return '—';
    try {
      if (v is int) {
        return DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(v));
      }
      final dt = DateTime.parse(v.toString());
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return v.toString();
    }
  }

  static String _formatLocation(dynamic loc) {
    if (loc == null) return '—';
    if (loc is Map) {
      final lat = loc['lat'] ?? loc['latitude'] ?? '—';
      final lng = loc['lng'] ?? loc['lon'] ?? loc['longitude'] ?? '—';
      return 'Lat: $lat, Lon: $lng';
    }
    return loc.toString();
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ]),
    );
  }

  Future<void> _upload(BuildContext ctx, Map<String, dynamic> jsonData) async {
    final supabase = Supabase.instance.client;
    if (supabase == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Supabase not initialized')));
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    final model = InstallEventDataModel.fromMap(jsonData, currentUserId: user.id);

    // show progress
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await InstallEventDataModel.createInstallEvent(model);
      if (Navigator.canPop(ctx)) Navigator.pop(ctx); // remove loader
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Saved: ${resp['id'] ?? 'ok'}')));
      Navigator.of(ctx).pop(resp); // go back, return the response
    } catch (e) {
      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseJson(rawJson);
    if (parsed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Verify Installation Data')),
        body: const Center(child: Text('Invalid QR JSON')),
      );
    }

    final installedAtText = _formatInstalledAt(parsed['installedAt'] ?? parsed['installed_at']);
    final locationText = _formatLocation(parsed['location'] ?? parsed['loc']);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Installation Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _row('Client Event ID', (parsed['clientEventId'] ?? parsed['client_event_id'] ?? '—').toString()),
          _row('Type', (parsed['type'] ?? 'installation').toString()),
          _row('QR ID', (parsed['qrid'] ?? parsed['qrId'] ?? '—').toString()),
          _row('Asset ID', (parsed['asset_id'] ?? parsed['assetId'] ?? '—').toString()),
          _row('Installer', (parsed['installer_id'] ?? parsed['installerId'] ?? '—').toString()),
          _row('Track Section', (parsed['track_section'] ?? parsed['trackSection'] ?? '—').toString()),
          _row('Installed At', installedAtText),
          _row('Location', locationText),
          _row('Notes', (parsed['notes'] ?? '—').toString()),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _upload(context, parsed),
            child: const Text('Confirm & Upload'),
          ),
        ]),
      ),
    );
  }
}
