import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/home/presentation/widgets/home_banner_carousel.dart';

void main() {
  testWidgets(
    'server banners rotate, open their targets and refresh changed image URLs',
    (tester) async {
      final dio = Dio();
      addTearDown(dio.close);
      var requests = 0, version = 'one';
      String? target;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests++;
            expect(request.extra['skipSessionAuth'], isTrue);
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': [
                    for (final id in ['business', 'membership'])
                      {
                        'id': id,
                        'title': id,
                        'target': id == 'business' ? 'leads' : 'membership',
                        'imageUrl': '/api/v1/banners/home/$id/image?v=$version',
                      },
                  ],
                },
              ),
            );
          },
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dioProvider.overrideWithValue(dio)],
          child: MaterialApp(
            home: Scaffold(
              body: HomeBannerCarousel(onTap: (value) => target = value),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, 1);
      final page = tester.widget<PageView>(find.byType(PageView)).controller!;
      expect(page.page, 0);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(page.page, 1);
      await tester.tapAt(
        tester.getTopLeft(find.byType(PageView)) + const Offset(20, 20),
      );
      expect(target, 'membership');
      version = 'two';
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeBannerCarousel)),
      );
      await tester.runAsync(() async {
        container.invalidate(homeBannersProvider);
        await container.read(homeBannersProvider.future);
      });
      await tester.pumpAndSettle();
      expect(requests, 2);
      final slides = container.read(homeBannersProvider).requireValue;
      expect(slides.every((slide) => slide.url.endsWith('v=two')), isTrue);
      expect(find.byType(Image), findsWidgets);
      final image =
          tester.widget<Image>(find.byType(Image).last).image as ResizeImage;
      expect((image.imageProvider as NetworkImage).url, endsWith('v=two'));
      page.jumpToPage(0);
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getTopLeft(find.byType(PageView)) + const Offset(20, 20),
      );
      expect(target, 'leads');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('failed banner request offers retry without bundled artwork', (
    tester,
  ) async {
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) =>
            handler.reject(DioException(requestOptions: request)),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const MaterialApp(home: Scaffold(body: HomeBannerCarousel())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reload banners'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
