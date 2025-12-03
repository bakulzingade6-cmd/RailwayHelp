// lib/pages/inspection_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:majdur_p/datamodel/inspections_datamodel.dart';

class InspectionFormPage extends StatefulWidget {
  final Map<String, dynamic>? prefill; // scanned JSON (optional)
  const InspectionFormPage({super.key, this.prefill});

  @override
  State<InspectionFormPage> createState() => _InspectionFormPageState();
}

class _InspectionFormPageState extends State<InspectionFormPage> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _date;
  late TextEditingController _inspectorCtrl;
  late TextEditingController _assetIdCtrl;
  String _status = 'good';
  late TextEditingController _notesCtrl;
  late TextEditingController _vendorCtrl;
  String _severity = 'low';
  int _photosCount = 0;
  bool _loading = false;

  final List<String> _statusOptions = ['good', 'needs repair', 'critical'];
  final List<String> _severityOptions = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    final p = widget.prefill ?? {};

    // Prefill logic: support snake_case and camelCase keys
    _date = _parseDate(p['date'] ?? p['installedAt'] ?? p['installed_at']);
    _inspectorCtrl = TextEditingController(
      text: _toString(p['inspector'] ?? p['inspectorId'] ?? p['inspector_id']),
    );
    _assetIdCtrl = TextEditingController(
      text: _toString(p['asset_id'] ?? p['assetId'] ?? p['assetId']),
    );
    _status = _toString(p['status'], defaultValue: 'good');
    _notesCtrl = TextEditingController(text: _toString(p['notes']));
    _vendorCtrl = TextEditingController(text: _toString(p['vendor']));
    _severity = _toString(p['severity'], defaultValue: 'low');
    _photosCount = (p['photos_count'] ?? p['photosCount'] ?? 0) is num
        ? (p['photos_count'] ?? p['photosCount'] ?? 0) as int
        : int.tryParse(
                (p['photos_count'] ?? p['photosCount'] ?? 0).toString(),
              ) ??
              0;
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
    _inspectorCtrl.dispose();
    _assetIdCtrl.dispose();
    _notesCtrl.dispose();
    _vendorCtrl.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final model = InspectionDataModel(
        date: _date,
        inspector: _inspectorCtrl.text.trim(),
        assetId: _assetIdCtrl.text.trim(),
        status: _status,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        vendor: _vendorCtrl.text.trim().isEmpty
            ? null
            : _vendorCtrl.text.trim(),
        severity: _severity,
        photosCount: _photosCount,
      );

      final resp = await InspectionDataModel.createInspection(model);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved — id: ${resp['id'] ?? 'unknown'}')),
      );
      Navigator.of(context).pop(resp);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = _date != null
        ? DateFormat('yyyy-MM-dd').format(_date!)
        : 'Pick date';
    return Scaffold(
      appBar: AppBar(title: const Text('Inspection Form')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Date
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(dateText),
                trailing: TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick'),
                ),
              ),
              const SizedBox(height: 8),

              // Inspector
              TextFormField(
                controller: _inspectorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Inspector (required)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter inspector' : null,
              ),
              const SizedBox(height: 8),

              // Asset ID
              TextFormField(
                controller: _assetIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Asset ID (required)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter asset id' : null,
              ),
              const SizedBox(height: 12),

              // Status (3 options)
              const Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Column(
                children: _statusOptions.map((s) {
                  return RadioListTile<String>(
                    title: Text(s),
                    value: s,
                    groupValue: _status,
                    onChanged: (val) =>
                        setState(() => _status = val ?? _status),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Severity
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Severity'),
                value: _severity,
                items: _severityOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _severity = v ?? _severity),
              ),
              const SizedBox(height: 12),

              // Vendor
              TextFormField(
                controller: _vendorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Vendor (optional)',
                ),
              ),
              const SizedBox(height: 12),

              // Photos count
              Row(
                children: [
                  const Text(
                    'Photos count',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: _photosCount.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '$_photosCount',
                      onChanged: (v) =>
                          setState(() => _photosCount = v.round()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_photosCount'),
                ],
              ),
              const SizedBox(height: 12),

              // Notes
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 4,
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
