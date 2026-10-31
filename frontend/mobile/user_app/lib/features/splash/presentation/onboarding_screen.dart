import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardSlideData> _slides = const [
    _OnboardSlideData(
      titlePrefix: 'Tired of\n',
      highlightText: 'low-quality ',
      titleSuffix: 'leads?',
      subtitle:
          'Many service businesses spend time and money on leads that are irrelevant, fake, or not serious.',
      imagePath: 'assets/branding/onboarding_1.png',
    ),
    _OnboardSlideData(
      titlePrefix: 'Find genuine ',
      highlightText: 'civil work\n',
      titleSuffix: 'opportunities near you',
      subtitle:
          'Connect with homeowners, builders and developers who are looking for trusted civil work professionals.',
      imagePath: 'assets/branding/onboarding_2.png',
    ),
    _OnboardSlideData(
      titlePrefix: 'Find verified\ncustomers ',
      highlightText: 'near you\n',
      titleSuffix: 'for your painting services',
      subtitle:
          'Get genuine home painting enquiries from people in your area who are ready to hire.',
      imagePath: 'assets/branding/onboarding_3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    context.go(AppRouter.login);
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top branding wordmark
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/branding/nextlead_wordmark.webp',
                  width: 130,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Carousel Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Headline
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.montserrat(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(text: slide.titlePrefix),
                              TextSpan(
                                text: slide.highlightText,
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              TextSpan(text: slide.titleSuffix),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          slide.subtitle,
                          style: AppTextStyles.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondarySlate,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Main illustration
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              slide.imagePath,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Card with Skip, Dots, and Circular Arrow Button
            Container(
              padding: EdgeInsets.fromLTRB(
                28,
                16,
                28,
                MediaQuery.paddingOf(context).bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button
                  GestureDetector(
                    onTap: _completeOnboarding,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8E99A8),
                        ),
                      ),
                    ),
                  ),

                  // 3 Indicator dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_slides.length, (index) {
                      final isSelected = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 9 : 8,
                        height: isSelected ? 9 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primaryBlue
                              : const Color(0xFFDCE6F7),
                        ),
                      );
                    }),
                  ),

                  // Circular arrow button
                  InkWell(
                    onTap: _onNext,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0070FF), Color(0xFF0047FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x400047FF),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardSlideData {
  final String titlePrefix;
  final String highlightText;
  final String titleSuffix;
  final String subtitle;
  final String imagePath;

  const _OnboardSlideData({
    required this.titlePrefix,
    required this.highlightText,
    required this.titleSuffix,
    required this.subtitle,
    required this.imagePath,
  });
}
