import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'support_chat_view.dart';

import '../../../payments/presentation/widgets/wallet_card.dart';
import 'support_tickets_screen.dart';

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
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark,
    child: SupportChatView(
      messages: messages,
      input: input,
      loading: loading,
      sending: sending,
      signedIn: widget.signedIn,
      hasOlder: hasOlder,
      error: error,
      showTopics:
          widget.ticket == null ||
          (!humanRequested && !humanActive && ticketStatus != 'COMPLETED'),
      status: humanActive
          ? 'A representative has replied'
          : humanRequested
          ? 'Waiting for a representative'
          : 'NextLead Support',
      send: send,
      refresh: () => load(),
      older: () => load(older: true),
      signIn: widget.signIn,
      tickets: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => SupportTicketsScreen(
            dio: widget.dio,
            signedIn: widget.signedIn,
            signIn: widget.signIn,
          ),
        ),
      ),
      topic: (choice, label) {
        if (widget.ticket != null) {
          automatedHelp(choice);
        } else {
          input.text = label;
        }
      },
      wallet: !widget.signedIn
          ? const SizedBox.shrink()
          : Consumer(
              builder: (context, ref, _) {
                final wallet = ref.watch(walletProvider);
                return OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Wallet')),
                        body: const SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: WalletCard(),
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                  ),
                  label: Text(
                    wallet.when(
                      data: (data) =>
                          '\u20b9${((data['balancePaise'] as num? ?? 0) / 100).toStringAsFixed(0)}',
                      loading: () => '...',
                      error: (_, _) => 'Wallet',
                    ),
                  ),
                );
              },
            ),
    ),
  );
}
