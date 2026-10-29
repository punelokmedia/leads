import 'dart:async';
import 'package:flutter/material.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key, this.padding = EdgeInsets.zero});
  final EdgeInsetsGeometry padding;

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  static const _images = [
    'assets/branding/hero.webp',
    'assets/branding/steps.webp',
    'assets/branding/dashboard.webp',
  ];
  static const _titles = [
    'Find the leads.\nBuild real business.',
    'Find your next\nproject with NextLead.',
    'Ready to grow\nyour business?',
  ];
  final _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          !_pageController.hasClients ||
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
          ModalRoute.of(context)?.isCurrent != true ||
          MediaQuery.disableAnimationsOf(context) ||
          _pageController.position.isScrollingNotifier.value) {
        return;
      }
      _pageController.animateToPage(
        (_currentPage + 1) % _images.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: AspectRatio(
              aspectRatio: 64 / 23,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            _titles[index],
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Image.asset(
                          _images[index],
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_images.length, (index) {
              final selected = index == _currentPage;
              return Container(
                margin: EdgeInsets.symmetric(horizontal: 3.0),
                width: selected ? 18.0 : 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
