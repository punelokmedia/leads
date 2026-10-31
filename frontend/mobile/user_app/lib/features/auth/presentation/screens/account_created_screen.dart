import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF061139);
    const muted = Color(0xFF929DB6);
    const blue = Color(0xFF0047FF);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned(
              left: -65,
              right: -60,
              bottom: -140,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.055,
                  child: Image.asset(
                    'assets/Nextlead Mobile  App Asetes/NextLead Arrow only.png',
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = math.min(constraints.maxWidth / 393, 1.25);
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 26 * scale),
                    child: Column(
                      children: [
                        SizedBox(height: 12 * scale),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Back to home',
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            onPressed: () => context.go(AppRouter.homePath),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: navy,
                              size: 24 * scale,
                            ),
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        Image.asset(
                          'assets/branding/nextlead_wordmark.webp',
                          width: 178 * scale,
                          height: 64 * scale,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 38 * scale),
                        Image.asset(
                          'assets/Nextlead Mobile  App Asetes/You all set icon.png',
                          width: 192 * scale,
                          height: 192 * scale,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 22 * scale),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'You\u2019re all set!',
                            style: AppTextStyles.inter(
                              fontSize: 38 * scale,
                              fontWeight: FontWeight.w800,
                              color: navy,
                              letterSpacing: -1.5 * scale,
                            ),
                          ),
                        ),
                        SizedBox(height: 14 * scale),
                        Text(
                          'Your account has been created\nsuccessfully. Let\u2019s get you started\nwith NextLead.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w500,
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 34 * scale),
                        SizedBox(
                          width: double.infinity,
                          height: 53 * scale,
                          child: FilledButton(
                            onPressed: () => context.go(AppRouter.homePath),
                            style: FilledButton.styleFrom(
                              backgroundColor: blue,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Explore Now',
                                  style: AppTextStyles.inter(
                                    fontSize: 17 * scale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 14 * scale),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 27 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 36 * scale),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
