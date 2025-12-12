// lib/pages/installation_DB.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:majdur_p/datamodel/install_event_datamodel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InstallationDb extends StatefulWidget {
  final String rawJson;
  const InstallationDb({super.key, required this.rawJson});

  @override
  State<InstallationDb> createState() => _InstallationDbState();
}

class _InstallationDbState extends State<InstallationDb> {
  String? _engineerName;
  Map<String, dynamic>? _userLocation;

  Map<String, dynamic>? _parseJson(String raw) {
    try {
      final parsed = json.decode(raw);
      if (parsed is Map<String, dynamic>) return parsed;
      return null;
    } catch (e) {
      print('InstallationDb: JSON parse error -> $e');
      return null;
    }
  }

  static String _formatDate(dynamic v) {
    if (v == null) return 'Now';
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
        SizedBox(
          width: 100,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ]),
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permissions are permanently denied.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = {
        'lat': position.latitude,
        'lng': position.longitude,
      };
    });
    _showSnack('Location updated!');
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _upload(BuildContext ctx, Map<String, dynamic> jsonData) async {
    final supabase = Supabase.instance.client;

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('User not logged in. Cannot record installation.')));
      return;
    }

    final userIdentity = jsonData['installed_by'] ?? user.email ?? user.id;

    final model = InstallEventDataModel.fromMap(jsonData, currentUserId: userIdentity);

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final resp = await InstallEventDataModel.createInstallEvent(model);

      if (Navigator.canPop(ctx)) Navigator.pop(ctx);

      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Installation Recorded Successfully!'),
        backgroundColor: Colors.green
      ));

      Navigator.of(ctx).pop(resp);
    } catch (e) {
      if (Navigator.canPop(ctx)) Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Error uploading: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseJson(widget.rawJson);

    if (parsed == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid JSON Data Scanned')),
      );
    }

    final assetId = parsed['asset_id'] ?? parsed['assetId'] ?? 'Unknown';
    final installDate = _formatDate(parsed['installation_date'] ?? parsed['created_at']);
    final locationTxt = _formatLocation(_userLocation ?? parsed['location'] ?? parsed['loc']);
    final status = parsed['status'] ?? 'Installed';

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Installation')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Verify details before uploading:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            _row('Asset ID', assetId.toString()),
            _row('Date', installDate),
            _row('Location', locationTxt),
            _row('Status', status),

            const SizedBox(height: 20),
            const Text("Engineer Name:", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter Engineer Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _engineerName = value;
                });
              },
            ),

            const Spacer(),

            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location),
              ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                onPressed: () {
                  final updatedData = Map<String, dynamic>.from(parsed);
                  updatedData['installed_by'] = _engineerName;
                  updatedData['location'] = _userLocation;
                  _upload(context, updatedData);
                },
                child: const Text('CONFIRM & UPLOAD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
