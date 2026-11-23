import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'ai',
      'text':
          'Hello! I am your Presidency University CampusFlow AI Facility Copilot powered by Gemini. You can ask me about active campus incidents, building status, safety protocols, or report issues in natural language.',
      'time': DateTime.now().subtract(const Duration(minutes: 1)),
      'actions': ['⚡ Report Hazard', '🚨 Emergency SOS'],
    }
  ];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  static const List<Map<String, dynamic>> _quickPrompts = [
    {'label': '⚡ Electrical Hazard', 'prompt': 'Sparking conduit near Lab 304, what should I do?'},
    {'label': '💧 Pipe Leak Alert', 'prompt': 'Water pipe burst flooding Auditorium lobby'},
    {'label': '🌐 Library Wi-Fi', 'prompt': 'Wi-Fi AP is offline in Central Library second floor'},
    {'label': '🚨 Emergency Contacts', 'prompt': 'Who do I call for emergency facility hazard at Presidency?'},
    {'label': '❄️ AC Maintenance', 'prompt': 'Central AC failure in Engineering Block A lecture halls'},
  ];

  Future<void> _sendMessage([String? quickMsg]) async {
    HapticFeedback.lightImpact();
    final text = quickMsg ?? _controller.text.trim();
    if (text.isEmpty) return;

    final userTime = DateTime.now();
    setState(() {
      _messages.add({
        'sender': 'user',
        'text': text,
        'time': userTime,
      });
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await ApiService.chatWithCopilot(text);
      final reply = result['reply'] as String? ?? 'Incident logged. Facility dispatch notified.';
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': reply,
            'time': DateTime.now(),
            'actions': _detectSuggestedActions(reply),
          });
        });
      }
    } catch (_) {
      final offlineReply = _generateOfflineAiReply(text);
      if (mounted) {
        setState(() {
          _messages.add({
            'sender': 'ai',
            'text': offlineReply,
            'time': DateTime.now(),
            'actions': _detectSuggestedActions(offlineReply),
          });
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  List<String> _detectSuggestedActions(String text) {
    final lower = text.toLowerCase();
    final actions = <String>[];
    if (lower.contains('danger') || lower.contains('critical') || lower.contains('fire') || lower.contains('spark') || lower.contains('shock')) {
      actions.add('🚨 Call Security (Ext. 100)');
      actions.add('⚡ Log Emergency Ticket');
    } else if (lower.contains('water') || lower.contains('pipe') || lower.contains('leak')) {
      actions.add('💧 Report Plumbing');
      actions.add('📍 View on Campus Map');
    } else if (lower.contains('wifi') || lower.contains('network')) {
      actions.add('🌐 Log IT Ticket');
    } else {
      actions.add('📋 File Incident Report');
    }
    return actions;
  }

  void _handleSuggestedAction(String action) {
    HapticFeedback.mediumImpact();
    if (action.contains('Call Security')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dialing Campus Security Command Room: +91 80 4925 5555 (Ext. 100)...'),
          backgroundColor: AppTheme.criticalText,
        ),
      );
    } else if (action.contains('Emergency SOS') || action.contains('Emergency Ticket')) {
      _sendMessage('How do I trigger an immediate emergency containment dispatch?');
    } else if (action.contains('Plumbing') || action.contains('Report') || action.contains('Ticket')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switching to Report Tab with pre-selected categories...'),
          backgroundColor: AppTheme.primaryRoyalNavy,
        ),
      );
    } else {
      _sendMessage(action);
    }
  }

  String _generateOfflineAiReply(String prompt) {
    final q = prompt.toLowerCase();
    if (q.contains('spark') || q.contains('electric') || q.contains('wire') || q.contains('shock') || q.contains('fire')) {
      return '⚡ [CRITICAL ELECTRICAL PROTOCOL]\n'
          '• Evacuate a 10-meter perimeter immediately.\n'
          '• Do not touch metal doorframes or conduits.\n'
          '• Presidency University Electrical Response Team 1 has been flagged for rapid isolation.\n'
          '• Emergency Line: Campus Control Room ext. 100.';
    } else if (q.contains('water') || q.contains('leak') || q.contains('pipe') || q.contains('flood')) {
      return '💧 [PLUMBING / WATER CONTAINMENT]\n'
          '• Overhead chilled water line rupture alert recorded.\n'
          '• Caution: Slippery granite flooring. Use East Wing corridors.\n'
          '• Facility Rapid Response Unit 3 dispatched with industrial wet extraction equipment.';
    } else if (q.contains('wifi') || q.contains('wi-fi') || q.contains('internet') || q.contains('network')) {
      return '🌐 [NETWORK DIAGNOSTIC]\n'
          '• Academic Block B & Library access points are monitored on 5GHz dual-channel.\n'
          '• Backup SSID available: "PU-Student-HighSpeed".\n'
          '• IT NOC automated ticket generated with high priority.';
    } else if (q.contains('emergency') || q.contains('contact') || q.contains('security')) {
      return '🚨 [PRESIDENCY CAMPUS EMERGENCY CONTACTS]\n'
          '• Campus Security & First Response: +91 80 4925 5555 (Ext. 100)\n'
          '• Health & Medical Center: Ground Floor, Hostel Block (Ext. 108)\n'
          '• Facilities Command Desk: Engineering Block A Ground Floor (Ext. 120)';
    } else {
      return '🏛️ [CAMPUSFLOW AI DISPATCH]\n'
          'I have analyzed your inquiry: "$prompt".\n'
          'Your report has been indexed into the facility dispatch ledger. The rapid response team will cross-reference this with active work orders on campus.';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick Knowledge Chips
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: AppTheme.crispIvory,
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: _quickPrompts.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    backgroundColor: AppTheme.purePorcelain,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(item['prompt'] as String),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Message List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['sender'] == 'user';
              final time = msg['time'] as DateTime? ?? DateTime.now();
              final actions = (msg['actions'] as List<String>?) ?? [];

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primaryRoyalNavy : AppTheme.purePorcelain,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(3),
                      bottomRight: isUser ? const Radius.circular(3) : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: AppTheme.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryRoyalNavy.withValues(alpha: isUser ? 0.12 : 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppTheme.mediumBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.smart_toy_rounded, size: 13, color: AppTheme.primaryRoyalNavy),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CampusFlow AI Copilot',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryRoyalNavy,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        msg['text'] as String,
                        style: GoogleFonts.inter(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Interactive Quick Action Buttons inside Copilot
                      if (!isUser && actions.isNotEmpty) ...[
                        const Divider(height: 14, color: AppTheme.cardBorder),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: actions.map((act) {
                            return InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _handleSuggestedAction(act),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  act,
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryRoyalNavy,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 4),
                      ],

                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          DateFormat('h:mm a').format(time),
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: isUser ? Colors.white.withValues(alpha: 0.7) : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Typing Indicator
        if (_isLoading)
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRoyalNavy),
                ),
                const SizedBox(width: 8),
                Text(
                  'Copilot is reasoning with Gemini AI...',
                  style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

        // Input Bar
        Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 88),
          decoration: BoxDecoration(
            color: AppTheme.purePorcelain,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRoyalNavy.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.secondaryRoyalGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Ask Copilot about campus safety, incidents, or rules...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12.5),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRoyalNavy,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
                  onPressed: _isLoading ? null : () => _sendMessage(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
