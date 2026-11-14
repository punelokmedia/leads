import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';

void main() {
  testWidgets('Wallet layout stays visible on failure and retry recovers', (
    tester,
  ) async {
    var offline = true;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          walletProvider.overrideWith((ref) async {
            if (offline) throw Exception('Offline');
            return {'balancePaise': 123400, 'entries': [], 'nextCursor': null};
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(child: WalletCard(onBack: () {})),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Wallet'), findsWidgets);
    expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('Quick Add Money'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Retry loading wallet'));
    offline = false;
    await tester.tap(find.text('Retry loading wallet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1,234'), findsOneWidget);
    expect(find.text('Unavailable'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Wallet layout stays visible while loading', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [walletProvider.overrideWith((ref) => pending.future)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: WalletCard()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('AVAILABLE BALANCE'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    expect(find.text('Quick Add Money'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    pending.complete({'balancePaise': 0, 'entries': [], 'nextCursor': null});
  });
}
