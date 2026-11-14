import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../preview/business_details_page.dart' show accountText;

class SupportChatView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final TextEditingController input;
  final bool loading, sending, signedIn, hasOlder, showTopics;
  final String? error;
  final String status;
  final VoidCallback send, refresh, older, signIn, tickets;
  final void Function(String, String) topic;
  final Widget wallet;
  const SupportChatView({
    super.key,
    required this.messages,
    required this.input,
    required this.loading,
    required this.sending,
    required this.signedIn,
    required this.hasOlder,
    required this.showTopics,
    required this.error,
    required this.status,
    required this.send,
    required this.refresh,
    required this.older,
    required this.signIn,
    required this.tickets,
    required this.topic,
    required this.wallet,
  });
  static const blue = Color(0xFF0066FF),
      navy = Color(0xFF072565),
      muted = Color(0xFF8190AF);
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: navy),
                ),
                Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 130,
                  height: 44,
                ),
                const Spacer(),
                wallet,
                PopupMenuButton<String>(
                  tooltip: 'Support options',
                  icon: const Icon(Icons.more_vert, color: navy),
                  onSelected: (value) {
                    if (value == 'refresh') {
                      refresh();
                    } else if (value == 'tickets') {
                      tickets();
                    } else if (!sending) {
                      topic(value, _extraTopics[value]!);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh messages'),
                    ),
                    PopupMenuItem(
                      value: 'tickets',
                      child: Text('My support tickets'),
                    ),
                    if (showTopics)
                      for (final entry in _extraTopics.entries)
                        PopupMenuItem(
                          value: entry.key,
                          enabled: !sending,
                          child: Text(entry.value),
                        ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(
                    Icons.headset_mic_outlined,
                    color: blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chat with Support',
                        style: TextStyle(
                          color: navy,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        status,
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Send requests 24/7. We will reply here.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE3ECFA)),
          if (!signedIn)
            Expanded(
              child: Center(
                child: FilledButton(
                  onPressed: signIn,
                  child: const Text('Sign in to contact support'),
                ),
              ),
            )
          else ...[
            if (error != null)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(onPressed: refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: navy),
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.topCenter,
                        heightFactor: .829787,
                        child: Opacity(
                          opacity: .07,
                          child: Image.asset(
                            'assets/figma/chat-wallpaper.png',
                            fit: BoxFit.fill,
                            excludeFromSemantics: true,
                            cacheWidth: 780,
                          ),
                        ),
                      ),
                    ),
                    if (loading)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        itemCount: (messages.isEmpty ? 1 : messages.length) + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return hasOlder
                                ? TextButton(
                                    onPressed: older,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Load earlier messages'),
                                  )
                                : const SizedBox.shrink();
                          }
                          final i = index - 1;
                          final message = messages.isEmpty
                              ? <String, dynamic>{
                                  'sender': 'support',
                                  'text':
                                      'Hi there! 👋\nWelcome to NextLead Support. How can we help you today?',
                                }
                              : messages[i];
                          final day = messages.isEmpty
                              ? 'Today'
                              : _day(message);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (day.isNotEmpty &&
                                  (i == 0 || day != _day(messages[i - 1])))
                                _dateChip(day),
                              _bubble(context, message),
                              if (i == 0 && showTopics)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 40,
                                    top: 4,
                                    bottom: 20,
                                  ),
                                  child: _topics(),
                                ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEDF2FA))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      enabled: !sending,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      onSubmitted: (_) => send(),
                      style: const TextStyle(color: navy, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        counterText: '',
                        hintStyle: const TextStyle(color: muted),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FC),
                        contentPadding: const EdgeInsets.all(15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD6E1F5),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFD6E1F5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    tooltip: 'Send message',
                    onPressed: sending ? null : send,
                    style: IconButton.styleFrom(
                      backgroundColor: blue,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: sending
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ),
  );

  static const _extraTopics = {
    'LEAD_QUALITY': 'Lead quality',
    'DOWNLOAD': 'Downloads',
    'REFERRAL': 'Referrals',
    'HUMAN': 'Talk to a human',
  };

  Widget _dateChip(String day) => Center(
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(day, style: accountText(11, color: const Color(0xFF334155))),
    ),
  );

  Widget _topics() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0x996D86AF),
      border: Border.all(color: const Color(0xFFBFDBFE)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: LayoutBuilder(
      builder: (context, size) {
        final columns =
            size.maxWidth >= 250 &&
                MediaQuery.textScalerOf(context).scale(12) <= 15
            ? 2
            : 1;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in const [
              ('PAYMENT', 'Leads & purchases', Icons.work_outline),
              ('WALLET', 'Wallet & payments', Icons.credit_card),
              ('MEMBERSHIP', 'Membership', Icons.workspace_premium_outlined),
              ('ACCOUNT', 'Account & profile', Icons.person_outline),
              ('OTHER', 'Other issue', Icons.help_outline),
            ])
              SizedBox(
                width: item.$1 == 'OTHER'
                    ? size.maxWidth
                    : (size.maxWidth - (columns - 1) * 8) / columns,
                child: OutlinedButton.icon(
                  onPressed: sending ? null : () => topic(item.$1, item.$2),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: blue,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: accountText(
                      11,
                      color: blue,
                      weight: FontWeight.w600,
                    ),
                  ),
                  icon: Icon(item.$3, size: 15),
                  label: Text(item.$2, textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    ),
  );
  String _day(Map<String, dynamic> message) {
    final date = DateTime.tryParse('${message['createdAt']}')?.toLocal();
    if (date == null) return '';
    final now = DateTime.now();
    return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day
        ? 'Today'
        : DateFormat('d MMM yyyy').format(date);
  }

  Widget _bubble(BuildContext context, Map<String, dynamic> message) {
    final mine = message['sender'] == 'user';
    final date = DateTime.tryParse('${message['createdAt']}')?.toLocal();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            Image.asset(
              'assets/figma/chat-avatar.png',
              width: 32,
              height: 32,
              cacheWidth: 64,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? blue : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(mine ? 16 : 0),
                      topRight: Radius.circular(mine ? 0 : 16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                  ),
                  child: Text(
                    '${message['text']}',
                    style: accountText(
                      13,
                      color: mine ? Colors.white : const Color(0xFF0F172A),
                      weight: mine ? FontWeight.w500 : FontWeight.w400,
                    ).copyWith(height: 1.7),
                  ),
                ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(date),
                          style: accountText(
                            10,
                            color: const Color(0xFFA0B5D7),
                            weight: FontWeight.w400,
                          ),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 5),
                          Icon(
                            message['readAt'] != null
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: blue,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
