import 'package:flutter/material.dart';

import '../../common/constants.dart';
import 'models/plan.dart';
import 'views/bankinfo_screen.dart';
import 'views/plans_screen.dart';
import 'views/signup_screen.dart';

class MembershipUltimateRoute {
  static dynamic getRoutesWithSettings(RouteSettings settings) {
    final routes = {
      RouteList.memberShipUltimatePlans: (context) => PlansScreen(),
      RouteList.memberShipUltimateSignUp: (context) {
        final arguments = settings.arguments;
        if (arguments is Plan) {
          return MembershipSignUpScreen(plan: arguments);
        }
        return errorPage('planId is required');
      },
      RouteList.memberShipUltimateBankInfo: (context) {
        final arguments = settings.arguments;
        if (arguments is String) {
          return BankInfoScreen(bankInfo: arguments);
        }
        return errorPage('bankInfo is required');
      },
    };
    return routes;
  }

  static Widget errorPage(String title) => Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Text(title),
        ),
      );
}
