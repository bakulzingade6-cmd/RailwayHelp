// lib/pages/inspection/inspection_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:majdur_p/datamodel/inspections_datamodel.dart';

class InspectionFormPage extends StatefulWidget {
  final Map<String, dynamic>? prefill;
  const InspectionFormPage({super.key, this.prefill});

  @override
  State<InspectionFormPage> createState() => _InspectionFormPageState();
}

class _InspectionFormPageState extends State<InspectionFormPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  late TextEditingController _inspectedByCtrl;
  late TextEditingController _assetIdCtrl;
  // friendly UI default value
  String _partStatus = 'Pass';
  late TextEditingController _inspectDetailCtrl;
  int _photosCount = 0;
  String _severity = 'Low';
  bool _loading = false;

  // Friendly labels shown to user
  final List<String> _partStatusOptions = ['Pass', 'Fail', 'Needs Repair'];
  final List<String> _severityOptions = ['Low', 'Medium', 'High'];

  // MAP: UI label -> exact DB literal (update these if your DB literal is different)
  // From your constraint output we know DB expects "Good" and "Need Repair".
  // If DB uses a different literal for failure (e.g. 'Bad' or 'Fail'), change the right-hand value.
  final Map<String, String> _statusMap = {
    'Pass': 'Good',
    'Fail': 'Fail', // <-- replace 'Fail' with the exact allowed DB string if different
    'Needs Repair': 'Need Repair',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.prefill ?? {};
    _date = _parseDate(p['inspection_date'] ?? p['date']);
    _inspectedByCtrl = TextEditingController(text: _toString(p['inspected_by'] ?? p['inspector']));
    _assetIdCtrl = TextEditingController(text: _toString(p['asset_id'] ?? p['assetId']));
    // Accept incoming DB literal or UI label; try to present friendly UI label when prefill contains DB literal
    final prePart = _toString(p['part_status'] ?? p['status'], defaultValue: 'Pass');

    // If prefill contains a DB literal, convert it back to friendly UI label
    _partStatus = _uiLabelFromDb(prePart);
    _inspectDetailCtrl = TextEditingController(text: _toString(p['inspect_detail'] ?? p['notes']));
    _photosCount = (p['photos_count'] ?? 0) is num
        ? (p['photos_count'] ?? 0) as int
        : int.tryParse(p['photos_count']?.toString() ?? '0') ?? 0;
    _severity = _toString(p['severity'], defaultValue: 'Low');
  }

  // Convert DB literal back to the friendly UI label if possible
  String _uiLabelFromDb(String value) {
    // If incoming value already matches a friendly label, return it
    if (_partStatusOptions.contains(value)) return value;
    // Otherwise try to find a friendly label by matching map values
    final entry = _statusMap.entries.firstWhere(
      (e) => e.value.toLowerCase() == value.trim().toLowerCase(),
      orElse: () => const MapEntry('', ''),
    );
    if (entry.key.isNotEmpty) return entry.key;
    // fallback: return a friendly default
    return 'Pass';
  }

  static String _toString(dynamic v, {String defaultValue = ''}) {
    if (v == null) return defaultValue;
    return v.toString();
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _inspectedByCtrl.dispose();
    _assetIdCtrl.dispose();
    _inspectDetailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // Normalize / map friendly UI label to the exact DB literal
  String _normalizePartStatusForDb(String uiValue) {
    final mapped = _statusMap[uiValue];
    if (mapped != null && mapped.trim().isNotEmpty) return mapped.trim();
    // fallback: send trimmed uiValue (useful if mapping missing)
    return uiValue.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dbStatus = _normalizePartStatusForDb(_partStatus);
      // debug: verify exactly what we will send to DB
      // check your console/logs to confirm this matches the allowed strings from your constraint
      // Example console output: sending part_status="Good" (ui="Pass")
      // Remove or comment out this print in production if you want.
      // ignore: avoid_print
      print('DEBUG: sending part_status="$dbStatus" (ui="$_partStatus")');

      final model = InspectionDataModel(
        inspectionDate: _date,
        inspectedBy: _inspectedByCtrl.text.trim(),
        assetId: _assetIdCtrl.text.trim(),
        partStatus: dbStatus,
        inspectDetail: _inspectDetailCtrl.text.trim().isEmpty ? null : _inspectDetailCtrl.text.trim(),
        photosCount: _photosCount,
        severity: _severity,
      );
      final resp = await InspectionDataModel.createInspection(model);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved — id: ${resp['id'] ?? 'unknown'}')),
      );
      Navigator.of(context).pop(resp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date != null ? DateFormat('yyyy-MM-dd').format(_date!) : 'Pick date';

    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(dateText),
                trailing: TextButton(onPressed: _pickDate, child: const Text('Pick')),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _inspectedByCtrl,
                decoration: const InputDecoration(labelText: 'Inspected By (required)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter inspected by' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _assetIdCtrl,
                decoration: const InputDecoration(labelText: 'Asset ID (required)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter asset id' : null,
              ),
              const SizedBox(height: 12),
              const Text('Part Status', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: _partStatusOptions.map((s) {
                  return RadioListTile<String>(
                    title: Text(s),
                    value: s,
                    groupValue: _partStatus,
                    onChanged: (val) => setState(() => _partStatus = val ?? _partStatus),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Severity'),
                value: _severity,
                items: _severityOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _inspectDetailCtrl,
                decoration: const InputDecoration(labelText: 'Inspect Detail (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Photos count', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _photosCount.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '$_photosCount',
                      onChanged: (v) => setState(() => _photosCount = v.round()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_photosCount'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
