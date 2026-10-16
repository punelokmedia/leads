import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Parses rupees into paise without floating-point rounding.
int? walletAmountPaise(String value) {
  final text = value.trim();
  if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) return null;
  final parts = text.split('.');
  final rupees = int.tryParse(parts[0]);
  if (rupees == null || rupees > 100000) return null;
  final paise =
      rupees * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return paise >= 100 && paise <= 10000000 ? paise : null;
}

class WalletAmountDialog extends StatefulWidget {
  const WalletAmountDialog({super.key});

  @override
  State<WalletAmountDialog> createState() => _WalletAmountDialogState();
}

class _WalletAmountDialogState extends State<WalletAmountDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, walletAmountPaise(_controller.text));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add money'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Custom amount',
                prefixText: '₹ ',
                hintText: 'Enter amount',
              ),
              validator: (value) => walletAmountPaise(value ?? '') == null
                  ? 'Enter ₹1 to ₹1,00,000 (up to 2 decimals).'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in [100, 500, 1000, 2000])
                  ActionChip(
                    label: Text('₹$amount'),
                    onPressed: () {
                      _controller.text = '$amount';
                      _controller.selection = TextSelection.collapsed(
                        offset: _controller.text.length,
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Add up to ₹1,00,000 per top-up. Your bank or UPI app may apply lower transaction or daily limits.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _submit,
        child: const Text('Continue to payment'),
      ),
    ],
  );
}
