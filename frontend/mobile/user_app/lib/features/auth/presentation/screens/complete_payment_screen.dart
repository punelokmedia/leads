import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
// features/auth/presentation/screens/complete_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/payment_widgets.dart';
import '../../shared/auth_providers.dart';

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
