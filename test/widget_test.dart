import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_app/core/constants/app_colors.dart';
import 'package:jarvis_app/shared/widgets/orb/jarvis_orb.dart';

void main() {
  group('JarvisOrb', () {
    for (final mood in AssistantMood.values) {
      testWidgets('renders without throwing in ${mood.name} mood', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: JarvisOrb(mood: mood, size: 200)),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(JarvisOrb), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JarvisOrb(mood: AssistantMood.idle, onTap: () => tapped = true),
          ),
        ),
      );
      await tester.tap(find.byType(JarvisOrb));
      expect(tapped, isTrue);
    });
  });
}
