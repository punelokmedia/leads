import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/core/errors/error_handler.dart';

class LiveReferralSection extends StatefulWidget {
  const LiveReferralSection({super.key, required this.dio});
  final Dio dio;
  @override
  State<LiveReferralSection> createState() => _LiveReferralSectionState();
}

class _LiveReferralSectionState extends State<LiveReferralSection> {
  late Future<Map<String, dynamic>> _data;
  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await widget.dio.get('api/v1/referrals/me');
    if (response.data['success'] != true) {
      throw StateError('Unable to load referrals.');
    }
    return Map<String, dynamic>.from(response.data['data']);
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(ErrorHandler.handle(snapshot.error).message),
                TextButton(
                  onPressed: () => setState(() => _data = _load()),
                  child: const Text('Retry'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final code = data['referralCode'].toString();
          final link = data['referralLink']?.toString();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite friends',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your code. Your friend can enter it during profile setup.',
              ),
              const SizedBox(height: 12),
              SelectableText(code),
              TextButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copy code'),
                onPressed: () async {
                  try {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral code copied')),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to copy. Select the code to copy it.',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              Text(
                'Invited: ${data['invited']} · Qualified: ${data['qualified']} · Pending: ${data['pending']}',
              ),
              if (link != null) ...[
                SelectableText(link),
                TextButton(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation link copied')));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to copy. Select the link to copy it.')));
                      }
                    }
                  },
                  child: const Text('Copy invitation link'),
                ),
              ],
              const Text('Download app — coming soon (preview)'),
              if (data['appliedReferral'] != null)
                Text('Your referral: ${data['appliedReferral']['status']}'),
            ],
          );
        },
      ),
    ),
  );
}
