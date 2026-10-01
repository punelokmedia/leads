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
    'assets/Images/home/Banner_1.png',
    'assets/Images/home/Banner_2.png',
    'assets/Images/home/Banner_3.png',
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
                itemBuilder: (context, index) => Image.asset(
                  _images[index],
                  fit: BoxFit.contain,
                  semanticLabel:
                      'Home banner ${index + 1} of ${_images.length}',
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
