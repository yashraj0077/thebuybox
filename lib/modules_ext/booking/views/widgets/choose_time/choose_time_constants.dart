import 'package:flutter/material.dart';
import '../../../../../generated/l10n.dart';

class ChooseTimeConstants {
  static List defineLimitTime(BuildContext context) => [
        {
          'title': S.of(context).morning,
          'timeStart': 6,
          'timeEnd': 11,
        },
        {
          'title': S.of(context).afternoon,
          'timeStart': 12,
          'timeEnd': 16,
        },
        {
          'title': S.of(context).evening,
          'timeStart': 17,
          'timeEnd': 21,
        }
      ];
}
