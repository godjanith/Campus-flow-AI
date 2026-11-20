import 'package:flutter/material.dart';
import 'report_screen.dart';
import 'tickets_screen.dart';
import 'ai_chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TicketsScreen(),
    const ReportScreen(),
    const AiChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CampusFlow AI Mobile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tickets'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Report'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Assistant'),
        ],
      ),
    );
  }
}
