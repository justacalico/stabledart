import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stabledart/models/app_settings.dart';
import 'package:stabledart/services/settings_manager.dart';
import 'package:stabledart/state/version_store.dart';
import 'package:stabledart/utils/number_format.dart';
import 'package:stabledart/views/pages/settings_page.dart';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stabledart/services/version_checker.dart';

import 'test_helpers.dart';

VersionStore _makeVersionStore() => VersionStore(
    VersionChecker(
        client: MockClient((r) async => http.Response(
            '[{"tag_name":"v9.9.9"}]', 200))),
    () => '0.1.0');

void main() {
  setUp(setupMockChannels);

  Future<void> openTab(WidgetTester tester, String name) async {
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
  }

  testWidgets('General settings tab', (tester) async {
    await pumpPage(tester, const SettingsPage());
    expect(find.text('Appearance'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<AppThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<AppThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deutsch').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<NumberFormatMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Period').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<HolidayMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('On').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    final scroll = find.byType(ListView);
    await tester.dragUntilVisible(find.text('Copy'), scroll,
        const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(find.text('Remove Symlinks on Shutdown'),
        scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: find.text('Remove Symlinks on Shutdown'),
                matching: find.byType(ListTile))
            .first,
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    expect(find.text('Add Variable'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Variable'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).at(0), 'MY_VAR');
    await tester.enterText(
        find.byType(TextField).at(1), 'my value');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
        find.text('Show Unsupported Python Versions'), scroll,
        const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: find.text('Show Unsupported Python Versions'),
                matching: find.byType(ListTile))
            .first,
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
        find.text('Infinite Scrolling'), scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: find.text('Infinite Scrolling'),
                matching: find.byType(ListTile))
            .first,
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find
            .ancestor(
                of: find.text('Auto Search on Load'),
                matching: find.byType(ListTile))
            .first,
        matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
        find.text('History Size'), scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.descendant(
        of: find
            .ancestor(
                of: find.text('History Size'), matching: find.byType(ListTile))
            .first,
        matching: find.byType(Slider)), const Offset(60, 0));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
        find.text('Maximum Simultaneous Downloads'), scroll,
        const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.drag(find.descendant(
        of: find
            .ancestor(
                of: find.text('Maximum Simultaneous Downloads'),
                matching: find.byType(ListTile))
            .first,
        matching: find.byType(Slider)), const Offset(50, 0));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
        find.text('Discord Rich Presence'), scroll, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
  });

  testWidgets('General settings directory pickers', (tester) async {
    await pumpPage(tester, const SettingsPage());
    final scroll = find.byType(ListView);
    await tester.dragUntilVisible(find.text('Data Directory'), scroll,
        const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change').first);
    await tester.pumpAndSettle();
    expect(find.text('Select Data Directory'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '/new/data');
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change').last);
    await tester.pumpAndSettle();
    expect(find.text('Select Models Folder'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '/new/models');
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('Inference settings tab', (tester) async {
    final settings = TestProviders.memorySettings(
        seed: (s) => s..['inferenceModelDirectory'] = '/models/x');
    await pumpPage(tester, const SettingsPage(), settings: settings);
    await openTab(tester, 'Inference');
    expect(find.text('/models/x'), findsOneWidget);
    expect(find.text('Default Steps'), findsOneWidget);
    for (final slider in find.byType(Slider).evaluate().toList()) {
      await tester.drag(
          find.byWidget(slider.widget), const Offset(40, 0));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
  });

  testWidgets('Account settings tab', (tester) async {
    await pumpPage(tester, const SettingsPage());
    await openTab(tester, 'Accounts');
    expect(find.text('Not signed in'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'testuser');
    await tester.tap(find.textContaining('lykos.ai'));
    await tester.pump();
    await tester.tap(find.text('Sign In').last);
    await tester.pumpAndSettle();
    expect(find.text('testuser'), findsOneWidget);

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'civitkey');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'hfkey');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'gkey');
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
  });

  testWidgets('Update settings tab', (tester) async {
    await pumpPage(tester, const SettingsPage());
    await openTab(tester, 'Updates');
    expect(find.text('Check for updates'), findsOneWidget);
    await tester.tap(find.text('Check Now'));
    await tester.pumpAndSettle();
    expect(find.textContaining('up to date'), findsOneWidget);
    await tester.tap(find.text('View Releases'));
    await tester.pump();
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
  });

  testWidgets('Update settings with failed check', (tester) async {
    final vs = VersionStore(
        VersionChecker(
            client: MockClient(
                (r) async => http.Response('x', 500))),
        () => '0.1.0');
    await pumpPage(tester, const SettingsPage(), versionStore: vs);
    await vs.checkForUpdates();
    await openTab(tester, 'Updates');
    expect(find.textContaining('Check failed'), findsOneWidget);
  });

  testWidgets('Update settings with update available', (tester) async {
    final vs = _makeVersionStore();
    await pumpPage(tester, const SettingsPage(), versionStore: vs);
    await vs.checkForUpdates();
    await openTab(tester, 'Updates');
    expect(find.textContaining('9.9.9'), findsWidgets);
    await tester.tap(find.text('Release Page'));
    await tester.pump();
  });

  testWidgets('Notification settings tab', (tester) async {
    await pumpPage(tester, const SettingsPage());
    await openTab(tester, 'Notifications');
    expect(find.text('Notification Level'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<NotificationLevel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Important').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<NotificationLevel>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();
  });

  testWidgets('Analytics settings tab', (tester) async {
    await pumpPage(tester, const SettingsPage());
    await openTab(tester, 'Analytics');
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    final sm = tester
        .element(find.byType(SettingsPage))
        .read<SettingsManager>();
    expect(sm.settings.analyticsEnabled, isTrue);
  });
}
