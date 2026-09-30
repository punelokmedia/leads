import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LiveSupportScreen extends StatefulWidget {
  final Dio dio;
  final bool signedIn;
  final VoidCallback signIn;
  const LiveSupportScreen({
    super.key,
    required this.dio,
    required this.signedIn,
    required this.signIn,
  });
  @override
  State<LiveSupportScreen> createState() => _LiveSupportScreenState();
}

class _LiveSupportScreenState extends State<LiveSupportScreen> {
  final input = TextEditingController();
  final messages = <Map<String, dynamic>>[];
  Timer? timer;
  bool loading = true, sending = false, fetching = false, hasOlder = false;
  String? error, pendingId, pendingText;
  static const path = 'api/v1/support/messages';

  @override
  void initState() {
    super.initState();
    if (widget.signedIn) {
      load();
      timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
    } else {
      loading = false;
    }
  }

  Future<void> load({bool older = false}) async {
    if (fetching) return;
    fetching = true;
    try {
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

  @override
  void dispose() {
    timer?.cancel();
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chat with Support'),
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
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Send requests 24/7. Our support team will reply here.',
                  ),
                ),
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
                                      child: Text(
                                        '${m['sender'] == 'user' ? 'You' : 'Support'}: ${m['text']}',
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
