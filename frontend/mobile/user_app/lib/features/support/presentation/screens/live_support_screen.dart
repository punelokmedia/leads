import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LiveSupportScreen extends StatefulWidget {
  final Dio dio;
  final bool signedIn;
  final VoidCallback signIn;
  final Map<String, dynamic>? ticket;
  const LiveSupportScreen({
    super.key,
    required this.dio,
    required this.signedIn,
    required this.signIn,
    this.ticket,
  });
  @override
  State<LiveSupportScreen> createState() => _LiveSupportScreenState();
}

class _LiveSupportScreenState extends State<LiveSupportScreen>
    with WidgetsBindingObserver {
  final input = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  Timer? timer;
  bool loading = true, sending = false, fetching = false, hasOlder = false;
  String? error, pendingId, pendingText;
  String get conversation => widget.ticket == null
      ? 'api/v1/support'
      : 'api/v1/support/tickets/${widget.ticket!['_id']}';
  String get path => '$conversation/messages';
  String? ticketStatus;
  bool humanRequested = false, humanActive = false;
  String helpIssue = 'PAYMENT';
  static const helpOptions = [
    'PAYMENT',
    'WALLET',
    'LEAD_QUALITY',
    'DOWNLOAD',
    'MEMBERSHIP',
    'REFERRAL',
    'ACCOUNT',
    'OTHER',
  ];

  @override
  void initState() {
    super.initState();
    helpIssue = '${widget.ticket?['issue'] ?? 'PAYMENT'}';
    WidgetsBinding.instance.addObserver(this);
    if (widget.signedIn) {
      load();
      timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          load();
        }
      });
    } else {
      loading = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.signedIn) load();
  }

  @override
  void didUpdateWidget(covariant LiveSupportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn == widget.signedIn) return;
    timer?.cancel();
    messages.clear();
    if (widget.signedIn) {
      loading = true;
      load();
      timer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          load();
        }
      });
    } else {
      loading = false;
    }
  }

  Future<void> load({bool older = false}) async {
    if (fetching) return;
    fetching = true;
    try {
      if (widget.ticket != null && !older) {
        final ticketResponse = await widget.dio.get(conversation);
        if (mounted) {
          setState(() {
            ticketStatus = '${ticketResponse.data['data']['status']}';
            humanRequested =
                ticketResponse.data['data']['humanRequestedAt'] != null;
            humanActive = ticketResponse.data['data']['humanReplyAt'] != null;
          });
        }
      }
      final response = await widget.dio.get(
        path,
        queryParameters: older && messages.isNotEmpty
            ? {'before': messages.first['_id']}
            : null,
      );
      if (response.data['success'] != true) {
        throw StateError('Support unavailable');
      }
      if (!mounted) return;
      final rows = List<Map<String, dynamic>>.from(response.data['data']);
      setState(() {
        if (older || messages.isEmpty) hasOlder = rows.length == 100;
        final byId = {
          for (final m in messages) m['_id']: m,
          for (final m in rows) m['_id']: m,
        };
        messages
          ..clear()
          ..addAll(byId.values);
        messages.sort((a, b) => '${a['_id']}'.compareTo('${b['_id']}'));
        error = null;
      });
      if (rows.isNotEmpty) {
        await widget.dio.post(
          '$conversation/read',
          data: {'through': rows.last['_id']},
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              error = 'Could not load support messages. Tap refresh to retry.',
        );
      }
    } finally {
      fetching = false;
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (sending || text.isEmpty) return;
    if (pendingText != text) {
      pendingText = text;
      pendingId = DateTime.now().microsecondsSinceEpoch.toString();
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final response = await widget.dio.post(
        path,
        data: {'text': text, 'clientId': pendingId},
      );
      if (response.data['success'] != true) throw StateError('Send failed');
      if (!mounted) return;
      final message = Map<String, dynamic>.from(response.data['data']);
      setState(() {
        if (!messages.any((m) => m['_id'] == message['_id'])) {
          messages.add(message);
        }
        input.clear();
        pendingId = null;
        pendingText = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Message not confirmed. Your text is kept; tap Send to retry.',
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> automatedHelp(String choice) async {
    if (sending || widget.ticket == null) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await widget.dio.post(
        '$conversation/automation',
        data: {'choice': choice},
      );
      await load();
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not confirm your support option. Tap again to retry.',
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.ticket == null
            ? 'Chat with Support'
            : '${widget.ticket!['ticketId']}',
      ),
      actions: [
        if (widget.signedIn)
          IconButton(
            onPressed: () => load(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
          ),
      ],
    ),
    body: !widget.signedIn
        ? Center(
            child: FilledButton(
              onPressed: widget.signIn,
              child: const Text('Sign in to contact support'),
            ),
          )
        : SafeArea(
            child: Column(
              children: [
                if (widget.ticket != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${(ticketStatus ?? '${widget.ticket!['status']}').toLowerCase().replaceAll('_', ' ')}\n${widget.ticket!['description']}',
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Send requests 24/7. Our support team will reply here.',
                  ),
                ),
                if (widget.ticket != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      humanActive
                          ? 'A human representative has replied in this conversation.'
                          : humanRequested
                          ? 'Transferred to human support. A representative will reply here when available.'
                          : 'Automated support: choose an issue for guidance.',
                    ),
                  ),
                  if (!humanRequested &&
                      !humanActive &&
                      ticketStatus != 'COMPLETED')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: helpIssue,
                              items: helpOptions
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(
                                        value.toLowerCase().replaceAll(
                                          '_',
                                          ' ',
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: sending
                                  ? null
                                  : (value) =>
                                        setState(() => helpIssue = value!),
                            ),
                          ),
                          TextButton(
                            onPressed: sending
                                ? null
                                : () => automatedHelp(helpIssue),
                            child: const Text('Get help'),
                          ),
                        ],
                      ),
                    ),
                  if (!humanRequested &&
                      !humanActive &&
                      ticketStatus != 'COMPLETED')
                    TextButton(
                      onPressed: sending ? null : () => automatedHelp('HUMAN'),
                      child: const Text('Still need help - talk to a human'),
                    ),
                ],
                if (widget.ticket == null)
                  Wrap(
                    spacing: 8,
                    children: ['Payment help', 'Lead quality', 'Account help']
                        .map(
                          (topic) => ActionChip(
                            label: Text(topic),
                            onPressed: sending
                                ? null
                                : () {
                                    input.text = topic;
                                  },
                          ),
                        )
                        .toList(),
                  ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (hasOlder)
                  TextButton(
                    onPressed: () => load(older: true),
                    child: const Text('Load earlier messages'),
                  ),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                      ? const Center(child: Text('How can we help you?'))
                      : ListView(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          children: messages.reversed
                              .map(
                                (m) => Align(
                                  alignment: m['sender'] == 'user'
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m['sender'] == 'user'
                                                ? 'You'
                                                : '${m['authorName'] ?? 'Support representative'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('${m['text']}'),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${DateTime.tryParse('${m['createdAt']}')?.toLocal() ?? ''}${m['sender'] == 'user' ? (m['readAt'] != null ? ' · Read by support' : ' · Sent') : ''}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: input,
                          enabled: !sending,
                          maxLength: 2000,
                          onSubmitted: (_) => send(),
                          decoration: const InputDecoration(
                            hintText: 'Type your message',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: sending ? null : send,
                        tooltip: 'Send message',
                        icon: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
  );
}
