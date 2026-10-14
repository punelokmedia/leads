import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'live_support_screen.dart';

class SupportTicketsScreen extends StatefulWidget {
  final Dio dio;
  final bool signedIn;
  final VoidCallback signIn;
  const SupportTicketsScreen({
    super.key,
    required this.dio,
    required this.signedIn,
    required this.signIn,
  });
  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  final description = TextEditingController();
  final tickets = <Map<String, dynamic>>[];
  String issue = 'PAYMENT';
  String? error, pendingId, pendingDescription, pendingIssue;
  bool loading = false, creating = false;
  int page = 1, pages = 1;
  static const issues = [
    'PAYMENT',
    'WALLET',
    'LEAD_QUALITY',
    'DOWNLOAD',
    'MEMBERSHIP',
    'REFERRAL',
    'ACCOUNT',
    'OTHER',
  ];
  String label(String value) => value.toLowerCase().replaceAll('_', ' ');
  @override
  void initState() {
    super.initState();
    if (widget.signedIn) load();
  }

  @override
  void didUpdateWidget(covariant SupportTicketsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signedIn != widget.signedIn) {
      tickets.clear();
      if (widget.signedIn) load();
    }
  }

  Future<void> load() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await widget.dio.get(
        'api/v1/support/tickets',
        queryParameters: {'page': page},
      );
      if (!mounted) return;
      setState(() {
        tickets
          ..clear()
          ..addAll(List<Map<String, dynamic>>.from(response.data['data']));
        pages = response.data['pagination']['totalPages'] as int;
      });
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not load tickets. Tap refresh to retry.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> create() async {
    final value = description.text.trim();
    if (creating || value.isEmpty) return;
    if (pendingDescription != value || pendingIssue != issue) {
      pendingId = DateTime.now().microsecondsSinceEpoch.toString();
      pendingDescription = value;
      pendingIssue = issue;
    }
    setState(() {
      creating = true;
      error = null;
    });
    try {
      final response = await widget.dio.post(
        'api/v1/support/tickets',
        data: {'issue': issue, 'description': value, 'clientId': pendingId},
      );
      if (!mounted) return;
      final ticket = Map<String, dynamic>.from(response.data['data']);
      description.clear();
      pendingId = null;
      pendingDescription = null;
      pendingIssue = null;
      page = 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket ${ticket['ticketId']} created')),
      );
      await load();
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Ticket creation not confirmed. Your description is kept; retry safely.',
        );
      }
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Support tickets'),
      actions: [
        if (widget.signedIn)
          IconButton(
            onPressed: loading ? null : load,
            icon: const Icon(Icons.refresh),
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
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Raise a ticket',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              DropdownButtonFormField<String>(
                initialValue: issue,
                decoration: const InputDecoration(labelText: 'Issue'),
                items: issues
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(label(value)),
                      ),
                    )
                    .toList(),
                onChanged: creating
                    ? null
                    : (value) => setState(() => issue = value!),
              ),
              TextField(
                controller: description,
                enabled: !creating,
                maxLength: 2000,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue',
                ),
              ),
              FilledButton(
                onPressed: creating ? null : create,
                child: Text(creating ? 'Creating...' : 'Create ticket'),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 24),
              const Text(
                'My tickets',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (loading) const LinearProgressIndicator(),
              if (!loading && tickets.isEmpty) const Text('No tickets yet.'),
              ...tickets.map(
                (ticket) => Card(
                  child: ListTile(
                    title: Text('${ticket['ticketId']}'),
                    subtitle: Text(
                      '${label('${ticket['issue']}')} - ${label('${ticket['status']}')}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LiveSupportScreen(
                            dio: widget.dio,
                            signedIn: widget.signedIn,
                            signIn: widget.signIn,
                            ticket: ticket,
                          ),
                        ),
                      );
                      if (mounted) load();
                    },
                  ),
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: loading || page <= 1
                        ? null
                        : () {
                            page--;
                            load();
                          },
                    child: const Text('Previous'),
                  ),
                  Text('Page $page'),
                  TextButton(
                    onPressed: loading || page >= pages
                        ? null
                        : () {
                            page++;
                            load();
                          },
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
  );
}
