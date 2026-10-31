import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  static const blue = Color(0xFF0070FF),
      navy = Color(0xFF091B49),
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
                  onSelected: (value) =>
                      value == 'refresh' ? refresh() : tickets(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh messages'),
                    ),
                    PopupMenuItem(
                      value: 'tickets',
                      child: Text('My support tickets'),
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
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (hasOlder)
                          TextButton(
                            onPressed: older,
                            child: const Text('Load earlier messages'),
                          ),
                        if (messages.isEmpty)
                          _bubble(context, {
                            'sender': 'support',
                            'text':
                                'Hi there! 👋\nWelcome to NextLead Support.\nHow can we help you today?',
                          }),
                        if (showTopics)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 44,
                              top: 10,
                              bottom: 16,
                            ),
                            child: _topics(),
                          ),
                        for (var i = 0; i < messages.length; i++) ...[
                          if (i == 0 ||
                              _day(messages[i]) != _day(messages[i - 1]))
                            Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF2FA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _day(messages[i]),
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          _bubble(context, messages[i]),
                        ],
                      ],
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

  Widget _topics() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F8F7),
      border: Border.all(color: const Color(0xFFD9E7FF)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: LayoutBuilder(
      builder: (context, size) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in [
            ('PAYMENT', 'Leads & purchases', Icons.work_outline),
            ('WALLET', 'Wallet & payments', Icons.credit_card),
            ('MEMBERSHIP', 'Membership', Icons.workspace_premium_outlined),
            ('ACCOUNT', 'Account & profile', Icons.person_outline),
            ('OTHER', 'Other issue', Icons.help_outline),
            ('LEAD_QUALITY', 'Lead quality', Icons.fact_check_outlined),
            ('DOWNLOAD', 'Downloads', Icons.download_outlined),
            ('REFERRAL', 'Referrals', Icons.card_giftcard_outlined),
            ('HUMAN', 'Talk to a human', Icons.support_agent),
          ])
            SizedBox(
              width: size.maxWidth < 300
                  ? size.maxWidth
                  : (size.maxWidth - 8) / 2,
              child: OutlinedButton.icon(
                onPressed: sending ? null : () => topic(item.$1, item.$2),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: Icon(item.$3, color: blue, size: 21),
                label: Text(item.$2, style: const TextStyle(fontSize: 11)),
              ),
            ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: blue,
              child: Image.asset(
                'assets/branding/nextlead_arrow.png',
                width: 25,
                height: 25,
              ),
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
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: mine ? blue : const Color(0xFFF0F4FA),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    '${message['text']}',
                    style: TextStyle(
                      color: mine ? Colors.white : navy,
                      fontSize: 15,
                      height: 1.5,
                    ),
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
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        if (mine) ...[
                          const SizedBox(width: 5),
                          Icon(
                            message['readAt'] != null
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: muted,
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
