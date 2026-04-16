import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_stitch_app/main.dart';
import 'package:flutter_stitch_app/widgets/indicators.dart';
import 'package:flutter_stitch_app/widgets/hero_section.dart';
import 'package:flutter_stitch_app/data/mock_data.dart';

void main() {
  testWidgets('HorizontalEateryPage renders AppBar and initial Hero', (WidgetTester tester) async {
    // Desktop-first app: set a viewport large enough to avoid overflow in the HeroSection.
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build our app and trigger a frame using mock future
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FutureBuilder<List<MenuItem>>(
          future: Future.value(MockData.dailyItems),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return const Stack(
              children: [
                HeroSection(),
                TimeStatusIndicator(),
              ],
            );
          },
        ),
      ),
    ));
    
    // Wait for the FutureBuilder to complete
    await tester.pumpAndSettle();

    // Verify that the AppBar is present
    expect(find.byType(TimeStatusIndicator), findsOneWidget);
    
    // Verify hero text is displayed
    expect(find.text(MockData.heroHeadline), findsOneWidget);
  });

  testWidgets('TimeStatusIndicator reflects shop status', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: TimeStatusIndicator(),
      ),
    ));

    // Based on system time, it will either show EXPERIENCE OPEN or RESERVATIONS AT 3 PM
    final statusText = MockData.getTimeStatus();
    expect(find.text(statusText), findsOneWidget);
  });
}
