import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/labs_notifications_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsLabsPage extends ConsumerWidget {
  static Key tasksLabSwitch = const Key('labs-tasks');
  static Key pinsEditorLabSwitch = const Key('labs-pins-editor');

  const SettingsLabsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(L10n.of(context).labs),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text(L10n.of(context).labsAppFeatures),
              tiles: [
                const LabsNotificationsSettingsTile(),
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).encryptionBackupKeyBackup),
                  description: Text(L10n.of(context).sharedCalendarAndEvents),
                  initialValue:
                      ref.watch(isActiveProvider(LabsFeature.encryptionBackup)),
                  onToggle: (newVal) => updateFeatureState(
                    ref,
                    LabsFeature.encryptionBackup,
                    newVal,
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text(L10n.of(context).spaces),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).encryptedSpace),
                  description: Text(L10n.of(context).notYetSupported),
                  enabled: false,
                  initialValue: false,
                  onToggle: (newVal) {},
                ),
              ],
            ),
            SettingsSection(
              title: Text(L10n.of(context).chat),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).unreadMarkerFeatureTitle),
                  description: Text(
                    L10n.of(context).unreadMarkerFeatureDescription,
                  ),
                  initialValue:
                      ref.watch(isActiveProvider(LabsFeature.chatUnread)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.chatUnread, newVal),
                ),
              ],
            ),
            SettingsSection(
              title: Text(L10n.of(context).calendar),
              tiles: [
                SettingsTile.switchTile(
                  enabled: isSupportedPlatform,
                  title: Text(L10n.of(context).calendarSyncFeatureTitle),
                  description: Text(
                    L10n.of(context).calendarSyncFeatureDesc,
                  ),
                  initialValue: isSupportedPlatform &&
                      ref.watch(
                        isActiveProvider(LabsFeature.deviceCalendarSync),
                      ),
                  onToggle: (newVal) async {
                    await updateFeatureState(
                      ref,
                      LabsFeature.deviceCalendarSync,
                      newVal,
                    );
                    if (newVal) {
                      await initCalendarSync(ignoreRejection: true);
                      EasyLoading.showToast('Acter Calendars synced');
                    } else {
                      await clearActerCalendars();
                      EasyLoading.showToast('Acter Calendars removes');
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(L10n.of(context).apps),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).polls),
                  description: Text(L10n.of(context).pollsAndSurveys),
                  initialValue: ref.watch(isActiveProvider(LabsFeature.polls)),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.polls, newVal),
                  enabled: false,
                ),
                SettingsTile.switchTile(
                  title: Text(L10n.of(context).coBudget),
                  description:
                      Text(L10n.of(context).manageBudgetsCooperatively),
                  initialValue: ref.watch(
                    isActiveProvider(LabsFeature.cobudget),
                  ),
                  onToggle: (newVal) =>
                      updateFeatureState(ref, LabsFeature.cobudget, newVal),
                  enabled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
