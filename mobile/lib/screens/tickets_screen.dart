import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  late Future<List<dynamic>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = ApiService.getTickets();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _ticketsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tickets = snapshot.data ?? [];
        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final t = tickets[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(t['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${t['category']} • ${t['location']}\nStatus: ${t['status']}'),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(t['priority'], style: const TextStyle(fontSize: 10, color: Colors.white)),
                  backgroundColor: t['priority'] == 'Urgent' ? Colors.red : Colors.indigo,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
