import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_erp/core/theme/app_colors.dart';
import 'package:frontend_erp/core/theme/app_spacing.dart';
import 'package:frontend_erp/features/home/data/drawer_items.dart';
import 'package:frontend_erp/features/home/presentation/widgets/custom_drawer.dart';

const Size _phone = Size(390, 844);

Future<void> _pumpDrawer(
  WidgetTester tester, {
  int selectedIndex = DrawerItems.DASHBOARD,
}) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomDrawer(
          selectedIndex: selectedIndex,
          onItemSelected: (_) {},
          onLogout: () {},
        ),
      ),
    ),
  );
}

Container _drawerShell(WidgetTester tester) {
  return tester.widget<Container>(
    find
        .ancestor(of: find.byType(SafeArea), matching: find.byType(Container))
        .first,
  );
}

void main() {
  testWidgets('the drawer occupies exactly 75 percent of the screen width', (
    tester,
  ) async {
    await _pumpDrawer(tester);

    final Size size = tester.getSize(find.byType(CustomDrawer));

    expect(size.width, _phone.width * 0.75);
  });

  testWidgets('the right corners carry the 30px reference radius', (
    tester,
  ) async {
    await _pumpDrawer(tester);

    final decoration = _drawerShell(tester).decoration as BoxDecoration;
    final radius = decoration.borderRadius as BorderRadius;

    expect(radius.topRight, const Radius.circular(30));
    expect(radius.bottomRight, const Radius.circular(30));
    expect(radius.topLeft, Radius.zero);
    expect(radius.bottomLeft, Radius.zero);
  });

  testWidgets('the header logo uses the enlarged drawer logo height', (
    tester,
  ) async {
    await _pumpDrawer(tester);

    final image = tester.widget<Image>(find.byType(Image).first);

    expect(image.height, AppSizes.DRAWER_LOGO_HEIGHT);
    expect(image.fit, BoxFit.contain);
  });

  testWidgets('the enlarged logo still fits inside the drawer width', (
    tester,
  ) async {
    await _pumpDrawer(tester);

    final Size logo = tester.getSize(find.byType(Image).first);
    final Size drawer = tester.getSize(find.byType(CustomDrawer));

    expect(logo.width, lessThanOrEqualTo(drawer.width - AppSpacing.LG24 * 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('every drawer destination renders with its label', (
    tester,
  ) async {
    await _pumpDrawer(tester);

    for (final item in DrawerItems.all) {
      expect(find.text(item.title), findsOneWidget);
    }
  });

  testWidgets('only the selected item shows the 6px active dot', (
    tester,
  ) async {
    await _pumpDrawer(tester, selectedIndex: DrawerItems.ORDERS);

    final dots = tester.widgetList<Container>(find.byType(Container)).where((
      container,
    ) {
      final decoration = container.decoration;
      return decoration is BoxDecoration &&
          decoration.shape == BoxShape.circle &&
          decoration.color == AppColors.PRIMARY;
    }).toList();

    expect(dots, hasLength(1));

    final Size dotSize = tester.getSize(find.byWidget(dots.single));
    expect(dotSize, const Size(6, 6));
  });

  testWidgets('tapping a destination reports that index', (tester) async {
    int? tapped;

    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomDrawer(
            selectedIndex: DrawerItems.DASHBOARD,
            onItemSelected: (index) => tapped = index,
            onLogout: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text(DrawerItems.all[DrawerItems.REPORTS].title));

    expect(tapped, DrawerItems.REPORTS);
  });

  testWidgets('tapping logout invokes the logout callback', (tester) async {
    var loggedOut = false;

    tester.view.physicalSize = _phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomDrawer(
            selectedIndex: DrawerItems.DASHBOARD,
            onItemSelected: (_) {},
            onLogout: () => loggedOut = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.logout_rounded));

    expect(loggedOut, isTrue);
  });
}
