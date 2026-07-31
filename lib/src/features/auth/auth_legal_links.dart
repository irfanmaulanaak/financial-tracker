import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../theme.dart';

final _termsUri = Uri.parse('https://finsist.site/tos');
final _privacyUri = Uri.parse('https://finsist.site/policy');

class AuthLegalLinks extends StatelessWidget {
  const AuthLegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      minimumSize: Size.zero,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: FtColors.clay,
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    );

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Dengan melanjutkan, kamu menyetujui',
          style: TextStyle(color: FtColors.ink4, fontSize: 11),
        ),
        Link(
          uri: _termsUri,
          target: LinkTarget.blank,
          builder: (_, openLink) => TextButton(
            onPressed: openLink,
            style: linkStyle,
            child: const Text('Ketentuan Layanan'),
          ),
        ),
        Text('dan', style: TextStyle(color: FtColors.ink4, fontSize: 11)),
        Link(
          uri: _privacyUri,
          target: LinkTarget.blank,
          builder: (_, openLink) => TextButton(
            onPressed: openLink,
            style: linkStyle,
            child: const Text('Kebijakan Privasi'),
          ),
        ),
      ],
    );
  }
}
