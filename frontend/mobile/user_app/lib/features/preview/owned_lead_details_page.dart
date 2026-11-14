import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/network/dio_provider.dart';
import '../support/presentation/screens/support_tickets_screen.dart';
import 'lead_details_page.dart';
import 'preview_data.dart';
import 'profile_design.dart' show profileBackground;

class OwnedLeadDetailsPage extends ConsumerStatefulWidget {
  const OwnedLeadDetailsPage({
    super.key,
    required this.lead,
    required this.store,
    this.categoryName,
  });
  final PreviewLead lead;
  final PreviewStore store;
  final String? categoryName;
  @override
  ConsumerState<OwnedLeadDetailsPage> createState() =>
      _OwnedLeadDetailsPageState();
}

class _OwnedLeadDetailsPageState extends ConsumerState<OwnedLeadDetailsPage> {
  late Future<Map<String, dynamic>> details;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    details = load();
  }

  Future<Map<String, dynamic>> load() async {
    final response = await ref
        .read(dioProvider)
        .get('api/v1/leads/get-lead/${widget.lead.backendId}');
    if (response.data['success'] != true ||
        response.data['data']?['isPurchased'] != true) {
      throw StateError('Purchased lead access required.');
    }
    return Map<String, dynamic>.from(response.data['data']);
  }

  Future<void> markContacted(Map<String, dynamic> data) async {
    if (saving || data['contactedAt'] != null) return;
    setState(() => saving = true);
    try {
      final response = await ref
          .read(dioProvider)
          .patch('api/v1/leads/${widget.lead.backendId}/contacted');
      final timestamp = response.data['data']?['contactedAt'];
      if (response.data['success'] != true ||
          timestamp is! String ||
          DateTime.tryParse(timestamp) == null) {
        throw StateError('Contact status not confirmed.');
      }
      if (mounted) setState(() => data['contactedAt'] = timestamp);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save contact status. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> contact(String action, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final url = action == 'whatsapp'
        ? Uri.https('wa.me', digits.length == 10 ? '91$digits' : digits)
        : Uri(scheme: action == 'call' ? 'tel' : 'sms', path: phone);
    try {
      await const MethodChannel(
        'nextlead/contact',
      ).invokeMethod<void>('open', {'url': url.toString()});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open the app. You can select and copy the phone number.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: details,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final data = snapshot.data!;
        return LeadDetailsPreview(
          lead: widget.lead,
          store: widget.store,
          categoryName: widget.categoryName,
          clientDetails: data,
          contacted: data['contactedAt'] != null,
          contacting: saving,
          onMarkContacted: () => markContacted(data),
          onClientAction: contact,
          onReport: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SupportTicketsScreen(
                dio: ref.read(dioProvider),
                signedIn: true,
                signIn: () {},
                initialIssue: 'LEAD_QUALITY',
                initialDescription:
                    'Lead ${widget.lead.id} (${widget.lead.backendId}): ',
              ),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: profileBackground,
        appBar: AppBar(title: const Text('Lead Details')),
        body: Center(
          child: snapshot.hasError
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Unable to load your purchased lead. Check your access and retry.',
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => setState(() => details = load()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
