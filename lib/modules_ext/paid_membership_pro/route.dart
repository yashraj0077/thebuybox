import 'package:flutter/material.dart';

import '../../common/constants.dart';
import 'models/invoice.dart';
import 'models/plan.dart';
import 'views/confirmation_screen.dart';
import 'views/plans_screen.dart';
import 'views/signup_screen.dart';

class PaidMembershipProRoute {
  static dynamic getRoutesWithSettings(RouteSettings settings) {
    final routes = {
      RouteList.paidMemberShipProPlans: (context) => PlansScreen(),
      RouteList.paidMemberShipProSignUp: (context) {
        final arguments = settings.arguments;
        if (arguments is Plan) {
          return MembershipSignUpScreen(plan: arguments);
        }
        return errorPage('planId is required');
      },
      RouteList.paidMemberShipProConfirmation: (context) {
        final arguments = settings.arguments;
        if (arguments is Invoice) {
          return ConfirmationScreen(invoice: arguments);
        }
        return errorPage('invoice is required');
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
