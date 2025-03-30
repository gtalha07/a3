import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/features/auth/pages/register_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_screenshot/test_screenshot.dart';

import '../../../helpers/test_util.dart';

void main() {
  group('RegisterPage', () {
    late List<Override> providers;
    setUp(() {
      providers = [hasNetworkProvider.overrideWith((ref) => true)];
    });

    testWidgets('shows all required fields', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: providers,
        child: RegisterPage(),
      );

      // Verify all required fields are present
      expect(find.byKey(RegisterPage.nameField), findsOneWidget);
      expect(find.byKey(RegisterPage.usernameField), findsOneWidget);
      expect(find.byKey(RegisterPage.passwordField), findsOneWidget);
      expect(find.byKey(RegisterPage.tokenField), findsOneWidget);
      expect(find.byKey(RegisterPage.submitBtn), findsOneWidget);
    });

    testWidgets('validates required fields', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: providers,
        child: RegisterPage(),
      );

      // Try to submit without filling any fields

      final submitBtn = find.byKey(RegisterPage.submitBtn);
      await tester.ensureVisible(submitBtn);
      final BuildContext context = tester.element(submitBtn);
      final lang = L10n.of(context);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text(lang.emptyUsername), findsOneWidget);
      expect(find.text(lang.emptyPassword), findsOneWidget);
      expect(find.text(lang.emptyToken), findsOneWidget);
    });

    testWidgets('shows form fields and allows input', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: providers,
        child: RegisterPage(),
      );

      // Fill in all fields
      await tester.enterText(find.byKey(RegisterPage.nameField), 'Test User');
      await tester.enterText(
        find.byKey(RegisterPage.usernameField),
        'testuser',
      );
      await tester.enterText(
        find.byKey(RegisterPage.passwordField),
        'password123',
      );
      await tester.enterText(find.byKey(RegisterPage.tokenField), 'testtoken');

      // Verify the text was entered correctly
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.text('password123'), findsOneWidget);
      expect(find.text('testtoken'), findsOneWidget);
    });

    group('validates username format', () {
      testWidgets('rejects username with spaces', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.usernameField),
          'invalid username',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Verify validation message
        await tester.screenshot(path: 'screenshot.png');
        expect(
          find.text(lang.invalidUsernameFormat, skipOffstage: false),
          findsOneWidget,
        );
      });
      testWidgets('rejects username with non-alphanumeric characters', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.usernameField),
          'invalid:as',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.invalidUsernameFormat, skipOffstage: false),
          findsOneWidget,
        );
      });
    });

    group('validates password format', () {
      testWidgets('accepts password with spaces', (WidgetTester tester) async {
        await tester.pumpProviderWidget(
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          'password with spaces',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsNothing,
        );
      });
      testWidgets('rejects password ending with space', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          'password with spaces ',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsOneWidget,
        );
      });
      testWidgets('rejects password starting with a space', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: providers,
          child: RegisterPage(),
        );

        // Enter invalid username with spaces
        await tester.enterText(
          find.byKey(RegisterPage.passwordField),
          ' password with spaces',
        );

        final submitBtn = find.byKey(RegisterPage.submitBtn);
        await tester.ensureVisible(submitBtn);
        final BuildContext context = tester.element(submitBtn);
        final lang = L10n.of(context);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();
        // Verify validation message
        expect(
          find.text(lang.passwordHasSpacesAtEnds, skipOffstage: false),
          findsOneWidget,
        );
      });
    });
  });
}
