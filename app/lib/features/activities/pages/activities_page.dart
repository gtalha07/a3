import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/widgets/invitation_section/invitation_section_widget.dart';
import 'package:acter/features/activities/widgets/security_and_privacy_section/security_and_privacy_section_widget.dart';
import 'package:acter/features/activities/widgets/sync_section/sync_state_section_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> sectionWidgetList = [];

    // Syncing State Section
    final syncStateWidget = buildSyncingStateSectionWidget(context, ref);
    if (syncStateWidget != null) sectionWidgetList.add(syncStateWidget);

    // Invitation Section
    final invitationWidget = buildInvitationSectionWidget(context, ref);
    if (invitationWidget != null) sectionWidgetList.add(invitationWidget);

    // Security and Privacy Section
    final securityWidget = buildSecurityAndPrivacySectionWidget(context, ref);
    if (securityWidget != null) sectionWidgetList.add(securityWidget);

    return Scaffold(
      appBar: buildActivityAppBar(context),
      body: buildActivityBody(context, sectionWidgetList),
    );
  }

  AppBar buildActivityAppBar(BuildContext context) {
    final lang = L10n.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(lang.activities),
    );
  }

  Widget buildActivityBody(
    BuildContext context,
    List<Widget> sectionWidgetList,
  ) {
    final isActivityEmpty = sectionWidgetList.isEmpty;
    if (isActivityEmpty) return buildEmptyStateWidget(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionWidgetList,
      ),
    );
  }

  Widget buildEmptyStateWidget(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: lang.noActivityTitle,
        subtitle: lang.noActivitySubtitle,
        image: 'assets/images/empty_activity.svg',
      ),
    );
  }
}
