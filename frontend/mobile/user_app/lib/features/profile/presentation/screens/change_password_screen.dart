import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../preview/business_details_page.dart'
    show AccountPageHeader, accountText;
import '../../../preview/live_store.dart';
import '../../../preview/profile_design.dart' show profileBackground;
import '../../../../core/network/dio_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:user_app/core/utils/snackbar_helper.dart';
import '../widgets/edit_profile_widgets.dart';
import '../../shared/edit_profile_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late final _headerStore = LiveStore(ref.read(dioProvider), signedIn: true);
  final _formKey = GlobalKey<FormState>();
  final _existingPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  @override
  void dispose() {
    _headerStore.dispose();
    _existingPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onUpdate() async {
    if (ref.read(editProfileControllerProvider).isChangingPassword ||
        !_formKey.currentState!.validate()) {
      return;
    }
    await ref
        .read(editProfileControllerProvider.notifier)
        .changePassword(
          current: _existingPasswordCtrl.text.trim(),
          newPass: _newPasswordCtrl.text.trim(),
          onSuccess: () {
            if (!mounted) return;
            SnackbarHelper.showSuccess(
              context,
              "Password updated successfully",
            );
            context.pop();
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(
      editProfileControllerProvider.select((state) => state.isChangingPassword),
    );

    ref.listen(editProfileErrorProvider, (_, err) {
      if (err != null) {
        SnackbarHelper.showError(context, err);

        Future.microtask(
          () =>
              ref.read(editProfileControllerProvider.notifier).clearMessages(),
        );
      }
    });

    ref.listen<String?>(editProfileSuccessProvider, (_, msg) {
      if (msg != null) {
        SnackbarHelper.showSuccess(context, msg);

        Future.microtask(
          () =>
              ref.read(editProfileControllerProvider.notifier).clearMessages(),
        );
      }
    });

    return Scaffold(
      backgroundColor: profileBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccountPageHeader(store: _headerStore),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 17, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: accountText(
                              24,
                              color: const Color(0xFF0F172A),
                              weight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update your account password to keep your\naccount secure.',
                            style: accountText(
                              14,
                              color: const Color(0xFF9498A1),
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE57E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0ECFC)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/figma/password-banner.svg',
                                width: 48,
                                height: 48,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Use a strong password you haven’t used before.',
                                      style: accountText(
                                        13,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'This helps keep your account safe and secure.',
                                      style: accountText(
                                        12,
                                        weight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 36, 21, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _field(
                            'Current password',
                            'Enter current password',
                            _existingPasswordCtrl,
                            busy,
                            (value) => value == null || value.isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          _field(
                            'New password',
                            'Enter new password',
                            _newPasswordCtrl,
                            busy,
                            (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return value.length < 6
                                  ? 'Min 6 characters'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _field(
                            'Confirm new password',
                            'Re-enter new password',
                            _confirmPasswordCtrl,
                            busy,
                            (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return value != _newPasswordCtrl.text
                                  ? 'Passwords do not match'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE57E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                18,
                                16,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your password should include:',
                                    style: accountText(
                                      13,
                                      weight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  for (final text in [
                                    'At least 8 characters',
                                    'One uppercase and one lowercase letter',
                                    'At least one number or symbol',
                                  ])
                                    Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            text ==
                                                'At least one number or symbol'
                                            ? 0
                                            : 9,
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0066FF),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              text,
                                              style: accountText(
                                                12,
                                                weight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Tooltip(
                                message: 'Device sign-out is unavailable.',
                                child: SizedBox(
                                  width: 20,
                                  height: 24,
                                  child: Checkbox(
                                    value: false,
                                    onChanged: null,
                                    side: BorderSide(color: Color(0xFF0F172A)),
                                    fillColor: WidgetStatePropertyAll(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Log out of other devices',
                                      style: accountText(
                                        13,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Recommended if you don’t recognize recent activity.',
                                      style: accountText(
                                        12,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(23, 12, 22, 33),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton(
                            onPressed: busy ? null : _onUpdate,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 51),
                              shape: const StadiumBorder(),
                              textStyle: accountText(
                                15,
                                color: Colors.white,
                                weight: FontWeight.w700,
                              ),
                            ),
                            child: busy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Update Password'),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: OutlinedButton(
                              onPressed: busy ? null : () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                minimumSize: const Size(0, 29),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                ),
                                shape: const StadiumBorder(),
                                textStyle: accountText(
                                  14,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller,
    bool busy,
    String? Function(String?) validator,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: accountText(14, weight: FontWeight.w700)),
      const SizedBox(height: 8),
      ChangePasswordField(
        controller: controller,
        hintText: hint,
        enabled: !busy,
        validator: validator,
      ),
    ],
  );
}
