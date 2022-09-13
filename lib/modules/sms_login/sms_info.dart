import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../common/tools/tools.dart';
import '../../../../generated/l10n.dart';
import '../../../../widgets/common/custom_text_field.dart';
import 'sms_model.dart';

class SMSInfo extends StatefulWidget {
  final Function onSuccess;
  const SMSInfo({Key? key, required this.onSuccess}) : super(key: key);

  @override
  State<SMSInfo> createState() => _SMSInfoState();
}

class _SMSInfoState extends State<SMSInfo> {
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';

  final _firstNameNode = FocusNode();
  final _lastNameNode = FocusNode();
  final _emailNode = FocusNode();
  final _passNode = FocusNode();

  final _userExists = 'user-exists';

  void _showMessage(err) {
    if (err == _userExists) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(S.of(context).userExists),
        duration: const Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10.0,
          ),
          Text(
            S.of(context).accountSetup,
            style: theme.textTheme.headline5,
          ),
          Text(S.of(context).youNotBeAsked),
          const SizedBox(height: 20.0),
          CustomTextField(
            focusNode: _firstNameNode,
            autofillHints: const [AutofillHints.givenName],
            nextNode: _lastNameNode,
            onChanged: (value) => _firstName = value,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(labelText: S.of(context).firstName),
            hintText: S.of(context).enterYourFirstName,
          ),
          const SizedBox(height: 20.0),
          CustomTextField(
            focusNode: _lastNameNode,
            autofillHints: const [AutofillHints.familyName],
            nextNode: _emailNode,
            onChanged: (value) => _lastName = value,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(labelText: S.of(context).lastName),
            hintText: S.of(context).enterYourLastName,
          ),
          const SizedBox(height: 20.0),
          CustomTextField(
            focusNode: _emailNode,
            autofillHints: const [AutofillHints.email],
            nextNode: _passNode,
            onChanged: (value) => _email = value,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: S.of(context).enterYourEmailOrUsername),
            hintText: S.of(context).enterYourEmailOrUsername,
          ),
          const SizedBox(height: 20.0),
          CustomTextField(
            focusNode: _passNode,
            autofillHints: const [AutofillHints.password],
            onChanged: (value) => _password = value,
            keyboardType: TextInputType.text,
            obscureText: true,
            decoration: InputDecoration(labelText: S.of(context).password),
            hintText: S.of(context).enterYourPassword,
          ),
          const SizedBox(height: 20.0),
          Center(
            child: Consumer<SMSModel>(
              builder: (_, model, __) => TextButton(
                  onPressed: () async {
                    if (model.state != SMSModelState.loading) {
                      Tools.hideKeyboard(context);
                      final result = await model.isUserExisted(_email);

                      /// User is not registered. Create a user.
                      if (!result) {
                        final data = {
                          'firstName': _firstName,
                          'lastName': _lastName,
                          'username': _email,
                          'password': _password,
                          'phoneNumber': model.phoneNumber,
                        };
                        widget.onSuccess(data);
                      } else {
                        _showMessage(_userExists);
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: model.state == SMSModelState.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.check,
                          color: Colors.white,
                        )),
            ),
          ),
        ],
      ),
    );
  }
}
