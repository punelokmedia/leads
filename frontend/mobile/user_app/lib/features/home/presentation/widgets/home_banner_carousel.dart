import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/utils/media_url.dart';

typedef HomeBanner = ({String id, String title, String url, String target});
final homeBannersProvider = FutureProvider<List<HomeBanner>>(
  retry: (_, _) => null,
  (ref) async {
    final response = await ref
        .watch(dioProvider)
        .get(
          'api/v1/banners/home',
          options: Options(extra: {'skipSessionAuth': true}),
        );
    if (response.data['success'] != true || response.data['data'] is! List) {
      throw StateError('Banners unavailable.');
    }
    return [
      for (final row in (response.data['data'] as List).whereType<Map>())
        if (MediaUrl.resolve(row['imageUrl']?.toString()) case final String url)
          (
            id: '${row['id']}',
            title: '${row['title'] ?? ''}',
            url: url,
            target: '${row['target'] ?? ''}',
          ),
    ];
  },
);

class HomeBannerCarousel extends ConsumerStatefulWidget {
  const HomeBannerCarousel({
    super.key,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });
  final EdgeInsetsGeometry padding;
  final ValueChanged<String>? onTap;
  @override
  ConsumerState<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends ConsumerState<HomeBannerCarousel>
    with WidgetsBindingObserver {
  final controller = PageController();
  Timer? timer;
  int page = 0;
  int imageRetry = 0;
  DateTime checkedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void refresh() {
    if (DateTime.now().difference(checkedAt) < const Duration(minutes: 1) ||
        ref.read(homeBannersProvider).isLoading) {
      return;
    }
    checkedAt = DateTime.now();
    ref.invalidate(homeBannersProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        ModalRoute.of(context)?.isCurrent == true) {
      refresh();
    }
  }

  void tick(Timer _) {
    if (!mounted ||
        !controller.hasClients ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        ModalRoute.of(context)?.isCurrent != true ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    refresh();
    final state = ref.read(homeBannersProvider);
    final slides = state.hasValue ? state.value! : const <HomeBanner>[];
    if (slides.length < 2 ||
        MediaQuery.disableAnimationsOf(context) ||
        controller.position.isScrollingNotifier.value) {
      return;
    }
    controller.animateToPage(
      (page + 1) % slides.length,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeBannersProvider);
    if (state.hasValue && state.value!.isNotEmpty) {
      timer ??= Timer.periodic(const Duration(seconds: 4), tick);
    }
    ref.listen(homeBannersProvider, (_, next) {
      if (next.hasValue && next.value!.isNotEmpty) {
        if (!next.isLoading) checkedAt = DateTime.now();
      }
    });
    final slides = state.hasValue ? state.value! : const <HomeBanner>[];
    return Padding(
      padding: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 17 / 10,
              child: ColoredBox(
                color: const Color(0xFFE3EDFF),
                child: slides.isEmpty
                    ? Center(
                        child: state.isLoading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : TextButton.icon(
                                onPressed: () =>
                                    ref.invalidate(homeBannersProvider),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reload banners'),
                              ),
                      )
                    : LayoutBuilder(
                        builder: (context, bounds) => PageView.builder(
                          controller: controller,
                          itemCount: slides.length,
                          onPageChanged: (value) =>
                              setState(() => page = value),
                          itemBuilder: (context, index) {
                            final slide = slides[index];
                            final image = ResizeImage.resizeIfNeeded(
                              (bounds.maxWidth *
                                      MediaQuery.devicePixelRatioOf(context))
                                  .ceil(),
                              null,
                              NetworkImage(slide.url),
                            );
                            return Semantics(
                              label: slide.title,
                              button: widget.onTap != null,
                              child: InkWell(
                                onTap: widget.onTap == null
                                    ? null
                                    : () => widget.onTap!(slide.target),
                                child: Image(
                                  key: ValueKey('${slide.url}:$imageRetry'),
                                  image: image,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  excludeFromSemantics: true,
                                  errorBuilder: (_, _, _) => Center(
                                    child: IconButton(
                                      tooltip: 'Retry banner image',
                                      icon: const Icon(Icons.refresh),
                                      onPressed: () async {
                                        await image.evict();
                                        if (mounted) {
                                          setState(() => imageRetry++);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
          if (slides.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == page ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == page
                            ? const Color(0xFF0066FF)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
