import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/error_codes/error_codes.dart';
import '../../../../generated/l10n.dart';
import '../../../../models/entities/user.dart';
import 'sms_info.dart';
import 'sms_model.dart';
import 'sms_phone.dart';
import 'sms_verify.dart';

class SMSLoginScreen extends StatelessWidget {
  final Function(User user) onSuccess;

  const SMSLoginScreen({Key? key, required this.onSuccess}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SMSModel>(
        create: (_) => SMSModel(),
        lazy: false,
        child: SMSIndex(
          onSuccess: onSuccess,
        ));
  }
}

class SMSIndex extends StatefulWidget {
  final Function(User user) onSuccess;
  const SMSIndex({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<SMSIndex> createState() => _SMSIndexState();
}

class _SMSIndexState extends State<SMSIndex> {
  final _pageController = PageController();

  void _goToPage(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _showMessage(err) {
    if (err is ErrorType) {
      if (err == ErrorType.loginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err.getMessage(context)),
          duration: const Duration(seconds: 1),
        ));

        Future.delayed(const Duration(seconds: 1)).then((value) {
          Navigator.pop(context);
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err.getMessage(context)),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (err == 'invalid-phone-number') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).invalidPhoneNumber),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (err == 'too-many-requests') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).requestTooMany),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    if (err == 'invalid-verification-code') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).invalidSMSCode),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> verifyUser() async {
    final model = Provider.of<SMSModel>(context, listen: false);
    final isVerified = await model.smsVerify(_showMessage);
    if (isVerified) {
      final isUserExisted = await model.isPhoneNumberExisted();
      if (isUserExisted) {
        final user = await model.login();
        if (user != null) {
          widget.onSuccess(user);
        }
        return;
      }

      /// Go to info page
      _goToPage(2);
    }
  }

  Future<void> createAndLogin(data) async {
    final model = Provider.of<SMSModel>(context, listen: false);
    try {
      final user = await model.createUser(data);
      if (user != null) {
        _showMessage(ErrorType.registerSuccess);
        widget.onSuccess(user);
        return;
      }
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<SMSModel>(context, listen: false);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0.0,
      ),
      body: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              SMSInputWidget(
                onCallBack: () {
                  model.sendOTP(() => _goToPage(1), _showMessage, verifyUser);
                },
              ),
              SMSVerifyWidget(
                onCallBack: verifyUser,
              ),
              SMSInfo(
                onSuccess: (data) {
                  createAndLogin(data);
                },
              ),
            ],
          )),
    );
  }
}
