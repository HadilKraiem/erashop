import 'dart:developer';
import 'package:era_shop/View/UserLogin/demo_sign_in.dart';
import 'package:era_shop/utils/Strings/strings.dart';
import 'package:era_shop/utils/globle_veriables.dart';
import 'package:era_shop/utils/show_toast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_controller.dart';

class GoogleLoginController extends GetxController {
  final googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;

  GoogleSignInAccount get user => _user!;
  LoginController loginController = Get.put(LoginController());

  // ignore: prefer_typing_uninitialized_variables
  var googleUser;
  RxBool isLoading = false.obs;

  Future googleLogin() async {
    try {
      isLoading(true);
      googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;
      _user = googleUser;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (FirebaseAuth.instance.currentUser != null) {
        ///=====CALL API======///
        await loginController.getLoginData(
          image: user.photoUrl,
          email: user.email.toString(),
          password: "",
          loginType: 1,
          fcmToken: fcmToken,
          identity: identify,
          firstName: user.displayName.toString(),
          lastName: '',
          mobileNumber: '',
          countryCode: '',
        );
        if (loginController.userLogin!.status == true) {
          LoginSuccessUi.onShow(
            callBack: () {
              Get.back();
              Get.offAllNamed("/BottomTabBar");
            },
          );
        } else {
          displayToast(message: St.somethingWentWrong.tr);
        }
      } else {
        log("Google Login Current user is Null");
      }
    } on PlatformException catch (e, stackTrace) {
      log("Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}", error: e, stackTrace: stackTrace);
      if (kDebugMode) {
        print("Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}");
      }
      displayToast(message: "Google Sign-In failed (${e.code}): ${e.message ?? 'Check configuration'}");
    } on FirebaseAuthException catch (e, stackTrace) {
      log("Google Sign-In FirebaseAuthException: code=${e.code}, message=${e.message}", error: e, stackTrace: stackTrace);
      if (kDebugMode) {
        print("Google Sign-In FirebaseAuthException: code=${e.code}, message=${e.message}");
      }
      displayToast(message: "Auth error: ${e.message ?? e.code}");
    } catch (e, stackTrace) {
      log("Google Sign-In unexpected error: $e", error: e, stackTrace: stackTrace);
      if (kDebugMode) {
        print("Google Sign-In unexpected error: $e");
      }
      displayToast(message: St.somethingWentWrong.tr);
    } finally {
      isLoading(false);
    }
  }

  Future logOut() async {
    log("Google log Out");
    try {
      await googleSignIn.disconnect();
      FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print(e.code);
      }
    }
  }
}
