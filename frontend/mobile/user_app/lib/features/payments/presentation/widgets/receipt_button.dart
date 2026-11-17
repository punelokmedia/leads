import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/network/dio_provider.dart';

final receiptHistoryProvider = FutureProvider.autoDispose<List>((ref) async {
  final response = await ref.watch(dioProvider).get('api/v1/leads/history');
  if (response.data['success'] != true) {
    throw StateError('Unable to load order.');
  }
  return response.data['data'] as List;
});

final receiptOrderProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, leadId) async {
    final orders = await ref.watch(receiptHistoryProvider.future);
    for (final order in orders) {
      if (order['status'] == 'PAID' &&
          (order['items'] as List).any(
            (item) => '${item['leadId']}' == leadId,
          )) {
        return '${order['orderId']}';
      }
    }
    return null;
  },
);

Future<void> savePaymentReceipt(Dio dio, String orderId) async {
  final response = await dio.get<List<int>>(
    'api/v1/leads/receipt/$orderId',
    options: Options(responseType: ResponseType.bytes),
  );
  if (response.headers.value('content-type')?.contains('application/pdf') !=
          true ||
      response.data?.isNotEmpty != true) {
    throw StateError('Receipt unavailable.');
  }
  final directory = await getApplicationDocumentsDirectory();
  final id = orderId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final file = File('${directory.path}/NextLead_Receipt_$id.pdf');
  await file.writeAsBytes(response.data!, flush: true);
  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw StateError('PDF saved. Open it from your app documents.');
  }
}

class ReceiptButton extends ConsumerStatefulWidget {
  const ReceiptButton({super.key, this.orderId, this.leadId})
    : assert(orderId != null || leadId != null);
  final String? orderId;
  final String? leadId;
  @override
  ConsumerState<ReceiptButton> createState() => _ReceiptButtonState();
}

class _ReceiptButtonState extends ConsumerState<ReceiptButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final order = widget.orderId != null
        ? AsyncData<String?>(widget.orderId)
        : ref.watch(receiptOrderProvider(widget.leadId!));
    return order.when(
      loading: () => const Text('Loading receipt…'),
      error: (_, _) => TextButton(
        onPressed: () => ref.invalidate(receiptHistoryProvider),
        child: const Text('Retry receipt'),
      ),
      data: (id) => id == null
          ? const SizedBox.shrink()
          : TextButton.icon(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(busy ? 'Preparing PDF…' : 'Download Receipt'),
              onPressed: busy
                  ? null
                  : () async {
                      setState(() => busy = true);
                      try {
                        await savePaymentReceipt(ref.read(dioProvider), id);
                      } catch (_) {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open receipt. Please retry.',
                              ),
                            ),
                          );
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
            ),
    );
  }
}
