import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    final destination = _destination();
    _timer = Timer(const Duration(seconds: 2), () async {
      final route = await destination;
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        context.go(route);
      }
    });
  }

  Future<String> _destination() async {
    try {
      final values = await Future.wait<Object?>([
        const FlutterSecureStorage().read(key: 'auth_token'),
        SharedPreferences.getInstance(),
      ]);
      if ((values[0] as String?)?.trim().isNotEmpty == true) {
        return AppRouter.homePath;
      }
      return (values[1] as SharedPreferences).getBool('has_seen_onboarding') ==
              true
          ? AppRouter.login
          : AppRouter.onboardingPath;
    } catch (_) {
      return AppRouter.onboardingPath;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 393).clamp(.7, 1.4);
        return Stack(
          children: [
            Center(
              child: SizedBox(
                width: 261 * scale,
                height: 159 * scale,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    maxHeight: 181.15 * scale,
                    child: Image.asset(
                      'assets/figma/splash-imgRectangle.png',
                      width: 261 * scale,
                      height: 181.15 * scale,
                      fit: BoxFit.fill,
                      semanticLabel: 'NextLead',
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 17,
              right: 17,
              top: constraints.maxHeight * 727 / 852,
              child: const Text(
                'Discover real business opportunities\nand connect with genuine customers.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 16 / 14,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
