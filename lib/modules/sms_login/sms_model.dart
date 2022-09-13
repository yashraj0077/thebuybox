import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/cupertino.dart';
import 'package:inspireui/utils/logs.dart';

import '../../../../models/entities/user.dart';
import '../../../../services/services.dart';
import '../../common/config.dart';

enum SMSModelState { loading, loaded }

class SMSModel extends ChangeNotifier {
  var _state = SMSModelState.loaded;
  SMSModelState get state => _state;
  String _verificationId = '';
  String _smsCode = '';
  String get smsCode => _smsCode;
  String _phoneNumber = LoginSMSConstants.dialCodeDefault;
  String get phoneNumber => _phoneNumber;

  /// Update state
  void _updateState(state) {
    _state = state;
    notifyListeners();
  }

  Future<void> sendOTP(
    Function onPageChanged,
    Function onMessage,
    Function onVerify,
  ) async {
    try {
      _updateState(SMSModelState.loading);
      await Services().firebase.auth!.verifyPhoneNumber(
            phoneNumber: _phoneNumber,
            verificationCompleted: (auth.PhoneAuthCredential credential) async {
              _smsCode = credential.smsCode!;
              onVerify();
            },
            verificationFailed: (auth.FirebaseAuthException e) {
              onMessage(e.code);
              _updateState(SMSModelState.loaded);
            },
            codeSent: (String verificationId, int? resendToken) {
              _verificationId = verificationId;
              onPageChanged();
              _updateState(SMSModelState.loaded);

              ///Test with number +84764555949
              // Future.delayed(Duration(seconds: 3)).then((value) {
              //   _smsCode = '123456';
              //   onVerify();
              // });
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
          );
    } catch (err) {
      printLog(err);
      _updateState(SMSModelState.loaded);
    }
  }

  Future<bool> smsVerify(Function showMessage) async {
    _updateState(SMSModelState.loading);
    try {
      final credential = auth.PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: _smsCode);

      final user = await Services()
          .firebase
          .loginFirebaseCredential(credential: credential);
      if (user != null) {
        _phoneNumber = _phoneNumber.replaceAll('+', '').replaceAll(' ', '');
        return true;
      }
    } on auth.FirebaseAuthException catch (err) {
      printLog(err.message);
      showMessage(err.code);
    }
    _updateState(SMSModelState.loaded);
    return false;
  }

  Future<bool> isPhoneNumberExisted() async {
    final result = await Services().api.isUserExisted(phone: _phoneNumber);
    if (!result) {
      _updateState(SMSModelState.loaded);
    }
    return result;
  }

  Future<bool> isUserExisted(String username) async {
    _updateState(SMSModelState.loading);
    final result = await Services().api.isUserExisted(username: username);
    if (result) {
      _updateState(SMSModelState.loaded);
    }
    return result;
  }

  Future<User?> login() async {
    final result = await Services().api.loginSMS(token: _phoneNumber);
    if (result == null) {
      _updateState(SMSModelState.loaded);
    }
    _smsCode = '';
    return result;
  }

  Future<User?> createUser(data) async {
    try {
      final user = await Services().api.createUser(
            phoneNumber: data['phoneNumber'],
            firstName: data['firstName'],
            lastName: data['lastName'],
            username: data['username'],
            password: data['password'],
          );
      _updateState(SMSModelState.loaded);
      return user;
    } catch (e) {
      _updateState(SMSModelState.loaded);
      rethrow;
    }
  }

  void updatePhoneNumber(val) {
    _phoneNumber = val;
    notifyListeners();
  }

  void updateSMSCode(val) {
    _smsCode = val;
    notifyListeners();
  }
}
