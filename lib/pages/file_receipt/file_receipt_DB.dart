import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:majdur_p/datamodel/receipts_datamodel.dart';
import 'dart:convert';

class FileReceipt extends StatefulWidget {
  final String rawJson;
  const FileReceipt({super.key, required this.rawJson});

  @override
  State<FileReceipt> createState() => _FileReceiptState();
}

class _FileReceiptState extends State<FileReceipt> {
  Map<String, dynamic>? jsonData;
  DateTime? _selectedWarrantyDate; // State to hold user input

  @override
  void initState() {
    super.initState();
    jsonData = _parseJson(widget.rawJson);
  }

  // --- Helper Functions ---
  Map<String, dynamic>? _parseJson(String rawJson) {
    try {
      final parsed = json.decode(rawJson);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) {
        return Map<String, dynamic>.from(parsed);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Today (DB default)';
    try {
      DateTime dt;
      if (date is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(date);
      } else if (date is String) {
        dt = DateTime.parse(date);
      } else if (date is DateTime) {
        dt = date;
      } else {
        return date.toString();
      }
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  // --- Date Picker Logic ---
  Future<void> _pickWarrantyDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // Cannot be in the past? Adjust if needed
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedWarrantyDate) {
      setState(() {
        _selectedWarrantyDate = picked;
      });
    }
  }

  // --- Supabase Upload Logic ---
  Future<void> _uploadToSupabase(BuildContext context) async {
    if (jsonData == null) return;
    
    // Basic validation: items is required
    if (jsonData!['items'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Items field is required')),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // Parse Receipt Date
      DateTime? parsedReceiptDate;
      if (jsonData!['date'] != null) {
        if (jsonData!['date'] is int) {
          parsedReceiptDate = DateTime.fromMillisecondsSinceEpoch(jsonData!['date']);
        } else if (jsonData!['date'] is String) {
          parsedReceiptDate = DateTime.tryParse(jsonData!['date']);
        }
      }

      // Create ReceiptDataModel including Warranty
      final receipt = ReceiptDataModel(
        date: parsedReceiptDate,
        items: jsonData!['items'] is List
            ? List<String>.from(jsonData!['items'].map((e) => e.toString()))
            : [jsonData!['items'].toString()],
        value: jsonData!['value'] != null
            ? double.tryParse(jsonData!['value'].toString())
            : null,
        warranty: _selectedWarrantyDate, // Pass the user-selected date
      );

      // Insert into Supabase
      final insertedReceipt = await ReceiptDataModel.createReceipt(receipt);

      // Remove loading
      if (Navigator.canPop(context)) Navigator.pop(context);

      if (insertedReceipt != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Receipt uploaded! ID: ${insertedReceipt['id']}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload completed (no data returned)')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    } catch (e) {
      // Remove loading
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading: ${e.toString()}')),
      );
      debugPrint('Supabase upload error: $e');
    }
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    if (jsonData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Invalid QR Code Data')),
      );
    }

    final String dateText = _formatDate(jsonData!['date']);
    final String itemsText = jsonData!['items']?.toString() ?? '—';
    final String valueText = jsonData!['value']?.toString() ?? '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Receipt Data')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataRow(
                'ID',
                jsonData!['id']?.toString() ?? 'Auto-generated by DB',
              ),
              _buildDataRow('Date', dateText),
              _buildDataRow('Items', itemsText),
              _buildDataRow('Value', valueText),
              
              const Divider(height: 30, thickness: 1),
              
              // --- Warranty Input Section ---
              const Text(
                'Add Warranty Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _pickWarrantyDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedWarrantyDate == null
                            ? 'Select Warranty Expiration Date'
                            : _formatDate(_selectedWarrantyDate),
                        style: TextStyle(
                          color: _selectedWarrantyDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _uploadToSupabase(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm & Upload'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60, 
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}