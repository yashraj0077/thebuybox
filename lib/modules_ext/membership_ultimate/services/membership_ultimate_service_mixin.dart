import 'package:flutter/cupertino.dart';

import '../route.dart';

mixin MembershipUltimateServiceMixin {
  dynamic getMembershipUltimateRoutesWithSettings(RouteSettings settings) {
    return MembershipUltimateRoute.getRoutesWithSettings(settings);
  }
}
