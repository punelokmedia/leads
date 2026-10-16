import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_amount_dialog.dart';

void main() {
  test(
    'custom top-up converts rupees to exact paise and accepts boundaries',
    () {
      expect(walletAmountPaise('1'), 100);
      expect(walletAmountPaise('1234.56'), 123456);
      expect(walletAmountPaise('10.1'), 1010);
      expect(walletAmountPaise('100000'), 10000000);
      expect(walletAmountPaise('100000.00'), 10000000);
    },
  );
  test('rejects invalid or out-of-range money before checkout', () {
    for (final value in [
      '',
      '0',
      '0.99',
      '-1',
      '100000.01',
      '100001',
      '1.234',
      '1..2',
      'NaN',
      '1e5',
    ]) {
      expect(walletAmountPaise(value), isNull, reason: value);
    }
  });
}
