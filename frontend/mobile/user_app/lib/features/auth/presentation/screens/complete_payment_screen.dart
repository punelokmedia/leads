// features/auth/presentation/screens/complete_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:user_app/features/preview/live_home.dart';

class CompletePaymentScreen extends ConsumerStatefulWidget {
  const CompletePaymentScreen({super.key});

  @override
  ConsumerState<CompletePaymentScreen> createState() =>
      _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen> {
  @override
  Widget build(BuildContext context) {
    return const LiveHome(initialPage: 4);
  }
}
