import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:user_app/core/errors/error_handler.dart';
import 'referral_section.dart';

class LiveReferralSection extends StatefulWidget {
  const LiveReferralSection({super.key, required this.dio});
  final Dio dio;
  @override
  State<LiveReferralSection> createState() => _LiveReferralSectionState();
}

class _LiveReferralSectionState extends State<LiveReferralSection> {
  late Future<Map<String, dynamic>> _data;
  final history = <Map<String, dynamic>>[];
  String filter = 'All referrals';
  String? historyError;
  bool historyLoading = true;
  int page = 0, total = 0, request = 0;

  @override
  void initState() {
    super.initState();
    _data = _load();
    loadHistory();
  }

  Future<Map<String, dynamic>> _load() async {
    final response = await widget.dio.get('api/v1/referrals/me');
    if (response.data['success'] != true) {
      throw StateError('Unable to load referrals.');
    }
    final data = Map<String, dynamic>.from(response.data['data']);
    if ((data['referralCode']?.toString() ?? '').isEmpty) {
      throw StateError('Referral code unavailable.');
    }
    return data;
  }

  Future<void> loadHistory({bool more = false}) async {
    if (more && historyLoading) return;
    final current = ++request, next = more ? page + 1 : 1;
    setState(() {
      historyLoading = true;
      historyError = null;
      if (!more) history.clear();
    });
    try {
      final response = await widget.dio.get(
        'api/v1/referrals/history',
        queryParameters: {
          'page': next,
          'limit': 20,
          if (filter != 'All referrals')
            'status': filter == 'Successful' ? 'QUALIFIED' : 'PENDING',
        },
      );
      if (response.data['success'] != true) {
        throw StateError('History unavailable.');
      }
      final rows = List<Map<String, dynamic>>.from(response.data['data']);
      if (!mounted || current != request) return;
      setState(() {
        history.addAll(
          rows.where((row) => !history.any((old) => old['_id'] == row['_id'])),
        );
        page = next;
        total = (response.data['pagination']['total'] as num).toInt();
      });
    } catch (_) {
      if (mounted && current == request) {
        setState(() => historyError = 'Unable to load referral history.');
      }
    } finally {
      if (mounted && current == request) setState(() => historyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: _data,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Column(
          children: [
            Text(ErrorHandler.handle(snapshot.error).message),
            TextButton(
              onPressed: () {
                setState(() => _data = _load());
                loadHistory();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ReferralSection(
        data: snapshot.data,
        history: history,
        filter: filter,
        historyLoading: historyLoading,
        historyError: historyError,
        onFilter: (value) {
          if (value == filter) return;
          filter = value;
          loadHistory();
        },
        onMore: history.length < total ? () => loadHistory(more: true) : null,
        onRetry: () => loadHistory(more: history.isNotEmpty),
      );
    },
  );
}
