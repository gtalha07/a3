import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/display_name_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('DisplayNameWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required String displayName,
      TextStyle? style,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomDisplayNameProvider.overrideWith((a, b) => displayName),
        ],
        child: DisplayNameWidget(roomId: 'mock-room-1', style: style),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show display name when display name is not empty', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, displayName: 'Space Name');
      expect(find.text('Space Name'), findsOneWidget);
      expect(find.byType(SizedBox), findsNothing);
    });

    testWidgets('should show SizedBox when display name is empty', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, displayName: '');
      expect(find.text('Space Name'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should have maxLines set to 1', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, displayName: 'Space Name');
      final textWidget = tester.widget<Text>(find.text('Space Name'));
      expect(textWidget.maxLines, equals(1));
    });

    testWidgets('should have TextOverflow.ellipsis', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, displayName: 'Space Name');
      final textWidget = tester.widget<Text>(find.text('Space Name'));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets(
      'should use default theme style when no custom style is provided',
      (WidgetTester tester) async {
        await createWidgetUnderTest(tester: tester, displayName: 'Space Name');
        final textWidget = tester.widget<Text>(find.text('Space Name'));
        expect(
          textWidget.style,
          equals(
            Theme.of(
              tester.element(find.text('Space Name')),
            ).textTheme.bodyMedium,
          ),
        );
      },
    );

    testWidgets('should use custom style when provided', (
      WidgetTester tester,
    ) async {
      const customStyle = TextStyle(fontSize: 20, color: Colors.red);
      await createWidgetUnderTest(
        tester: tester,
        displayName: 'Space Name',
        style: customStyle,
      );
      final textWidget = tester.widget<Text>(find.text('Space Name'));
      expect(textWidget.style, equals(customStyle));
    });
  });
}
