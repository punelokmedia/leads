import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/profile_dashboard.dart';
import 'package:user_app/features/preview/profile_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    required VoidCallback onEdit,
    required VoidCallback onSaved,
    required VoidCallback onLogout,
    required ValueChanged<int> onSelect,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    addTearDown(store.dispose);
    store.profile = {
      'Full name': 'Akash Jain',
      'Email': 'ajaybansode@gmail.com',
      'Phone': '+91 98765 43210',
      'Business name': 'Interior Contractor',
      'Service category': 'Interior Designer',
      'City': 'Pune',
      'State': 'Maharashtra',
    };
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('profile-capture'),
            child: Scaffold(
              backgroundColor: profileBackground,
              body: NextLeadProfile(
                store: store,
                onEdit: onEdit,
                onWallet: () {},
                onNotifications: () {},
                onMembership: () {},
                onSaved: onSaved,
                onLeads: () {},
                onSupport: () {},
                onPassword: () {},
                onPreferences: () {},
                onTerms: () {},
                onLogout: onLogout,
                onMore: () {},
              ),
              bottomNavigationBar: ProfileBottomNav(onSelect: onSelect),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(ProfileDesign)),
      );
      await precacheImage(
        const AssetImage('assets/figma/profile-sample-avatar.png'),
        tester.element(find.byType(ProfileDesign)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'SVG profile renders and preserves edit, saved, logout and navigation actions',
    (tester) async {
      var edits = 0, saves = 0, logouts = 0, selected = -1;
      await mount(
        tester,
        const Size(393, 1294),
        onEdit: () => edits++,
        onSaved: () => saves++,
        onLogout: () => logouts++,
        onSelect: (i) => selected = i,
      );
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('UPDATE_PROFILE_PREVIEW')) {
        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('profile-capture')),
          );
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/profile-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('Edit Profile'));
      expect(edits, 1);
      await tester.tap(find.text('Saved'));
      expect(saves, 1);
      await tester.tap(find.text('My Leads'));
      expect(selected, 1);
      await tester.ensureVisible(find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(logouts, 0);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(logouts, 0);
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(logouts, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('profile fits narrow screens with enlarged text', (tester) async {
    await mount(
      tester,
      const Size(320, 700),
      textScale: 1.4,
      onEdit: () {},
      onSaved: () {},
      onLogout: () {},
      onSelect: (_) {},
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Logout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of NextLead?'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
