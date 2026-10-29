import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late final VideoPlayerController _video;
  Timer? _startupTimeout;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _video = VideoPlayerController.asset('assets/videos/nextlead_intro.mp4');
    _video.addListener(_onVideoChanged);
    // Continue if the device cannot load or play the intro.
    _startupTimeout = Timer(const Duration(seconds: 15), _continueIntoApp);
    unawaited(_playIntro());
  }

  Future<void> _playIntro() async {
    try {
      await _video.initialize();
      if (!mounted || _leaving) return;
      await _video.setLooping(false);
      await _video.setVolume(0);
      if (!mounted || _leaving) return;
      setState(() {});
      await _video.play();
    } catch (_) {
      await _continueIntoApp();
    }
  }

  void _onVideoChanged() {
    final value = _video.value;
    if (value.hasError || value.isCompleted) {
      unawaited(_continueIntoApp());
    }
  }

  Future<void> _continueIntoApp() async {
    if (!mounted || _leaving) return;
    _leaving = true;
    _startupTimeout?.cancel();
    final secureStorage = ref.read(secureStorageProvider);
    final token = await secureStorage.read(key: 'auth_token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      context.go(AppRouter.homePath);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    context.go(hasSeenOnboarding ? AppRouter.login : AppRouter.onboardingPath);
  }

  @override
  void dispose() {
    _startupTimeout?.cancel();
    _video.removeListener(_onVideoChanged);
    unawaited(_video.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: _video.value.isInitialized
            ? FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: _video.value.size.width,
                  height: _video.value.size.height,
                  child: VideoPlayer(_video),
                ),
              )
            : Center(
                child: Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 236,
                ),
              ),
      ),
    );
  }
}
