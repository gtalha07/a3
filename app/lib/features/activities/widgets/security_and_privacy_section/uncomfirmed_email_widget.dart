import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/security_privacy_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Widget? buildUnconfirmedEmailWidget(BuildContext context, WidgetRef ref) {
  final lang = L10n.of(context);
  final hasUnconfirmedEmails = ref.watch(hasUnconfirmedEmailAddresses);

  if (!hasUnconfirmedEmails) return null;

  return SecurityPrivacyWidget(
    icon: Atlas.envelope_minus_thin,
    iconColor: warningColor,
    title: lang.unconfirmedEmailsActivityTitle,
    subtitle: lang.unconfirmedEmailsActivitySubtitle,
    actions: [
      OutlinedButton(
        onPressed: () => context.goNamed(Routes.emailAddresses.name),
        child: Text(lang.confirmedEmailAddresses),
      ),
    ],
  );
}
