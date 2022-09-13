import 'package:flutter/cupertino.dart';

import '../route.dart';

mixin PaidMembershipProServiceMixin {
  dynamic getPaidMembershipProRoutesWithSettings(RouteSettings settings) {
    return PaidMembershipProRoute.getRoutesWithSettings(settings);
  }
}
