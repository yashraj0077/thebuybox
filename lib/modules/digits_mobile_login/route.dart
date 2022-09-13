import 'package:flutter/material.dart';

import '../../common/constants.dart';
import 'views/login_sms_screen.dart';
import 'views/signup_screen.dart';

class DigitsMobileLoginRoute {
  static dynamic getRoutesWithSettings(RouteSettings settings) {
    final routes = {
      RouteList.digitsMobileLoginSignUp: (context) =>
          const DigitsMobileLoginSignUpScreen(),
      RouteList.digitsMobileLogin: (context) => const DigitsMobileLoginScreen(),
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
