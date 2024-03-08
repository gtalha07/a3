import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationAcceptPage extends StatelessWidget {
  final String sender;
  final bool passive;

  const VerificationAcceptPage({
    super.key,
    required this.sender,
    required this.passive,
  });

  @override
  Widget build(BuildContext context) {
    final title = passive ? 'Verify This Session' : 'Verify Other Session';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: isDesktop ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
                  ),
                  const SizedBox(width: 5),
                  Text(title),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
          const Flexible(
            flex: 3,
            child: Center(
              child: SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 2,
            child: Text('Waiting for $sender'),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
