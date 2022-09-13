import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';

import '../models/entities/user.dart';

class BaseFirebaseServices {
  /// check if the Firebase is enable or not
  bool get isEnabled => false;

  Future<void> init() async {}

  dynamic getCloudMessaging() {}

  dynamic getCurrentUser() => null;

  /// Login Firebase with social account
  void loginFirebaseApple({authorizationCode, identityToken}) {}

  void loginFirebaseFacebook({token}) {}

  void loginFirebaseGoogle({token}) {}

  void loginFirebaseEmail({email, password}) {}

  dynamic loginFirebaseCredential({credential}) {}

  dynamic getFirebaseCredential({verificationId, smsCode}) {}

  /// save user to firebase
  void saveUserToFirestore({user}) {}

  /// verify SMS login
  dynamic getFirebaseStream() {}

  void verifyPhoneNumber(
      {phoneNumber,
      codeAutoRetrievalTimeout,
      codeSent,
      verificationCompleted,
      verificationFailed}) {}

  /// render Chat Screen
  Widget renderListChatScreen() => const SizedBox();

  Widget renderVendorListChatScreen({User? user}) => const SizedBox();

  Widget renderChatScreen({senderUser, receiverEmail, receiverName}) =>
      const SizedBox();

  /// load firebase remote config
  Future<FirebaseRemoteConfig?> loadRemoteConfig() async => null;

  /// init Firebase Dynamic link
  void initDynamicLinkService(context) {}

  void shareDynamicLinkProduct({itemUrl}) {}

  /// register new user with email and password
  void createUserWithEmailAndPassword({email, password}) {}

  void signOut() {}

  Future<String?> getMessagingToken() async => '';

  List<NavigatorObserver> getMNavigatorObservers() =>
      const <NavigatorObserver>[];

  void deleteAccount() {}
}
