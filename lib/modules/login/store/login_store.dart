import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import '../../../models/login_model.dart';
import '../../../api_service/api_service.dart';
import '../../../models/error_message_model.dart';
import '../../../models/forgot_password_model.dart';
import '../../../models/login_with_phone_model.dart';
import '../../../models/get_settings_data_model.dart';
import 'package:shusruta_lms/models/login_with_wt_model.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

part 'login_store.g.dart';

class LoginStore = _LoginStore with _$LoginStore;

abstract class _LoginStore extends InternetStore with Store {
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  bool isRemoveLoading = false;

  @observable
  bool isLoadingSettings = false;

  @observable
  String errorMessage = '';

  @observable
  Observable<LoginModel?> login = Observable<LoginModel?>(null);

  @observable
  Observable<LoginWithPhoneModel?> loginWithPhone =
      Observable<LoginWithPhoneModel?>(null);
  @observable
  Observable<LoginWithPhoneModel?> loginWithPhone2 =
      Observable<LoginWithPhoneModel?>(null);
  @observable
  Observable<Map<String, dynamic>> deleteDevice =
      Observable<Map<String, dynamic>>({});
  @observable
  Observable<LoginWithWtModel?> loginWithWt =
      Observable<LoginWithWtModel?>(null);

  @observable
  Observable<LoginWithPhoneModel?> verifyforgotOtpWithEmail =
      Observable<LoginWithPhoneModel?>(null);

  @observable
  Observable<ErrorMessageModel?> errorMessageOtp =
      Observable<ErrorMessageModel?>(null);

  @observable
  Observable<ForgotPasswordModel?> forgotPassWithMail =
      Observable<ForgotPasswordModel?>(null);

  @observable
  Observable<GetSettingsDataModel?> settingsData =
      Observable<GetSettingsDataModel?>(null);

  // Store restore user info for handling previously deleted accounts
  Map<String, dynamic>? _restoreUserInfo;

  Map<String, dynamic>? get restoreUserInfo => _restoreUserInfo;

  Future<void> onRegisterApiCall(String email, String password) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.loginUsers(email, password);
      login.value = result;
      if (result.token != null) {
        login.value = LoginModel(token: login.value?.token);
      } else {
        login.value = LoginModel(err: login.value?.err);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onLoginWithPhoneApiCall(String phone) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.loginWithPhoneUsers(phone);
      loginWithPhone.value = result;
      
      // Handle ERROR_REGISTER_User case
      if (result.err?.code == 'ERROR_REGISTER_User') {
        loginWithPhone.value = result; // Keep the full result with err field
      } else if (result.message != null) {
        loginWithPhone.value =
            LoginWithPhoneModel(message: loginWithPhone.value?.message);
      } else {
        loginWithPhone.value =
            LoginWithPhoneModel(error: loginWithPhone.value?.error);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onLoginWithWtApiCall(String phone, String deviceType) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.loginWtUsers(phone, deviceType);
      loginWithWt.value = result;

      if (result.token != null) {
        loginWithWt.value = LoginWithWtModel(token: loginWithWt.value?.token);
      } else if (result.message != null) {
        loginWithWt.value =
            LoginWithWtModel(message: loginWithWt.value?.message);
        //loginWithWt.value = LoginWithWtModel(error: loginWithWt.value?.error);
      } else if (result.error != null) {
        loginWithWt.value = LoginWithWtModel(error: loginWithWt.value?.error);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onVerifyOtpApiCall(
      String phone, String otp, String loggedInPlatform) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.verifyOtp(phone, otp, loggedInPlatform);
      loginWithPhone.value = result;
      if (result.token != null) {
        loginWithPhone.value = result;
      } else {
        loginWithPhone.value =
            LoginWithPhoneModel(message: loginWithPhone.value?.message);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onVerifyOtpPhoneApiCall(String phone, String otp,
      String deviceId, String deviceName, String deviceType) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.verifyOtpPhone(
          phone, otp, deviceId, deviceName, deviceType);
      loginWithPhone2.value = result;
      if (result.token != null) {
        loginWithPhone2.value = result;
      } else {
        loginWithPhone2.value =
            LoginWithPhoneModel(message: loginWithPhone2.value?.message);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteDeviceApiCall(String id, String token, String deviceId,
      String deviceName, String deviceType) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isRemoveLoading = true;
    try {
      final result = await _apiService.deleteDeviceInfo(
          id, token, deviceId, deviceName, deviceType);
      deleteDevice.value = result;
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isRemoveLoading = false;
    }
  }

  Future<void> onLoginApiCall(String email) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.loginWithGoogleUsers(email);
      login.value = result;
      if (result.token != null) {
        login.value = LoginModel(token: login.value?.token);
      } else {
        login.value = LoginModel(err: login.value?.err);
      }
    } catch (e) {
      debugPrint('Error loggin user: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onCreateNotificationToken(String fcmToken) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      // Existing usernotification storage — kept for backward compatibility
      // with push fan-out already wired against that table.
      final result = await _apiService.createNotificationToken(fcmToken);
      // debugPrint("fcm result");

      // Also register with the new DevicePushToken collection that powers
      // the per-user study reminder cron. This is additive and idempotent
      // (upserts on user_id + device_id). Fire-and-forget — login must not
      // fail because a secondary token register hiccuped.
      try {
        await _apiService.registerUserDeviceFcm(fcmToken: fcmToken);
      } catch (e) {
        debugPrint('registerUserDeviceFcm (secondary) failed: $e');
      }
    } catch (e) {
      debugPrint('Error creating user notification: $e');
    } finally {
      isLoading = false;
    }
  }

  Future<void> onSendOtpForgotEmail(String email) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.sendOtpToForgotEmail(email);
      
      // Check if the response contains error information for ERROR_REGISTER_User
      if (result['code'] == 'ERROR_REGISTER_User' && result['params'] != null) {
        // Handle the "user previously deleted" error
        final params = result['params'] as Map<String, dynamic>;
        final message = result['message'] ?? 'User previously deleted.';
        final restoreUser = params['restoreUser'] ?? false;
        
        errorMessageOtp.value = ErrorMessageModel(
          error: result['code'], 
          message: message
        );
        
        // Store additional info for handling restore functionality
        _restoreUserInfo = {
          'email': params['email'],
          'restoreUser': restoreUser,
          'message': message,
        };
      } else if (result['message'] != null) {
        // Success case
        errorMessageOtp.value = ErrorMessageModel(message: result['message']);
      } else if (result['error'] != null) {
        // Other error cases
        errorMessageOtp.value = ErrorMessageModel(error: result['error']);
      }
    } catch (e) {
      errorMessage = 'An error occurred.';
    } finally {
      isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> onRestoreUser(String email, String phone) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return null;
    }

    isLoading = true;
    try {
      final result = await _apiService.restoreUserAccount(email, phone);
      debugPrint('Restore user result: $result');
      return result;
    } catch (e) {
      debugPrint('Error restoring user: $e');
      errorMessage = 'An error occurred while restoring user account.';
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<void> onVerifyForgotOtpToMail(String email, String otp) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result = await _apiService.verifyForgotOtpWithMail(email, otp);
      verifyforgotOtpWithEmail.value = result;
      if (result.message != null) {
        verifyforgotOtpWithEmail.value = LoginWithPhoneModel(
            message: verifyforgotOtpWithEmail.value?.message);
      } else {
        verifyforgotOtpWithEmail.value =
            LoginWithPhoneModel(error: verifyforgotOtpWithEmail.value?.error);
      }
    } catch (e) {
      errorMessage = 'An error occurred.';
    } finally {
      isLoading = false;
    }
  }

  Future<void> onMailForgotPasswod(
      String pass, String confirmPass, String email) async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try {
      final result =
          await _apiService.forgotPasswithMail(pass, confirmPass, email);
      forgotPassWithMail.value = result;
      if (result.message != null) {
        forgotPassWithMail.value =
            ForgotPasswordModel(message: forgotPassWithMail.value?.message);
      } else {
        forgotPassWithMail.value =
            ForgotPasswordModel(err: forgotPassWithMail.value?.err);
      }
    } catch (e) {
      errorMessage = 'An error occurred.';
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetSettingsData() async {
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoadingSettings = true;
    try {
      final GetSettingsDataModel result = await _apiService.getSettingsData();
      await Future.delayed(const Duration(milliseconds: 1));
      // settingsData.value = result;
      // Persist key settings flags for other stores that cannot access this store directly.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(
            'settings_isInAPurchases', result.isInAPurchases == true);
      } catch (_) {}
      _setSettingsDetails(result);
    } catch (e) {
      errorMessage = 'An error occurred.';
    } finally {
      isLoadingSettings = false;
    }
  }

  @action
  void _setSettingsDetails(GetSettingsDataModel value) {
    settingsData.value = value;
  }
}
