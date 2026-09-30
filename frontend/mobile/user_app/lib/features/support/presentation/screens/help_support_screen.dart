import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/shared/auth_providers.dart';
import 'live_support_screen.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => LiveSupportScreen(
    dio: ref.watch(dioProvider),
    signedIn: ref.watch(isLoggedInProvider),
    signIn: () => context.push('/login'),
  );
}
