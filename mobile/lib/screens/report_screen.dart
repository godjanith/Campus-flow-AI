import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _category = 'Facilities';
  String _priority = 'Medium';
  bool _isLoading = false;

  void _submit() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.createTicket({
        'title': _titleController.text,
        'description': _descController.text,
        'location': _locationController.text.isEmpty ? 'Main Campus' : _locationController.text,
        'category': _category,
        'priority': _priority,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted & AI Triaged successfully!')),
      );
      _titleController.clear();
      _descController.clear();
      _locationController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Report Issue & AI Triage', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Issue Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            items: ['Facilities', 'IT Support', 'Academic', 'Campus Safety'].map((c) {
              return DropdownMenuItem(value: c, child: Text(c));
            }).toList(),
            onChanged: (val) => setState(() => _category = val!),
            decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _priority,
            items: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
              return DropdownMenuItem(value: p, child: Text(p));
            }).toList(),
            onChanged: (val) => setState(() => _priority = val!),
            decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location / Room', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
            onPressed: _isLoading ? null : _submit,
            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }
}
