
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';
import 'package:shusruta_lms/api_service/api_service.dart';
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';

import '../../../models/error_message_model.dart';
import '../../../models/login_with_phone_model.dart';
import '../../../models/preparing_for_model.dart';
import '../../../models/signup_model.dart';
import '../../../models/signup_with_phone_model.dart';
import '../../../models/standard_model.dart';
part 'signup_store.g.dart';

class SignupStore =  _SignupStore with _$SignupStore;

abstract class _SignupStore extends InternetStore with Store{
  final ApiService _apiService = ApiService();

  @observable
  bool isLoading = false;

  @observable
  String errorMessage = '';

  @observable
  Observable<ErrorMessageModel?> errorMessageOtp = Observable<ErrorMessageModel?>(null);

  @observable
  Observable<ErrorMessageModel?> errorMessageOtp2 = Observable<ErrorMessageModel?>(null);

  @observable
  Observable<SignupModel?> signup = Observable<SignupModel?>(null);

  @observable
  Observable<SignupWithPhoneModel?> signupWithPhone = Observable<SignupWithPhoneModel?>(null);

  @observable
  Observable<LoginWithPhoneModel?> registerWithEmail = Observable<LoginWithPhoneModel?>(null);

  @observable
  Observable<LoginWithPhoneModel?> registerWithEmail2 = Observable<LoginWithPhoneModel?>(null);

  @observable
  ObservableList<PreparingForModel?> preparingexams = ObservableList<PreparingForModel?>();

  @observable
  ObservableList<StandardModel?> standardList = ObservableList<StandardModel?>();

  // Store restore user info for handling previously deleted accounts
  Map<String, dynamic>? _restoreUserInfo;

  Map<String, dynamic>? get restoreUserInfo => _restoreUserInfo;

  // Future<void> onRegisterApiCall(String fullName, String dateOfBirth, String preparingValue, List<String> preparingFor,
  // String currentStatus, String phoneNumber, String email, String password, String confirmPass, bool isGoogle) async {
  //
  //   await checkConnectionStatus();
  //   if (!isConnected) {
  //     return;
  //   }
  //
  //   isLoading = true;
  //   try{
  //     final result = await _apiService.registerUsers(fullName, dateOfBirth, preparingValue,
  //         preparingFor, currentStatus, phoneNumber, email, password, confirmPass, isGoogle);
  //     signup.value = result;
  //     if (result.created != null) {
  //       signup.value = SignupModel(created: signup.value?.created);
  //     } else {
  //       signup.value = SignupModel(err: signup.value?.err);
  //     }
  //
  //     if (signup.value?.err?.code == 11000) {
  //       errorMessage = "Email already registered.";
  //     } else {
  //       errorMessage = signup.value?.err?.message ?? '';
  //     }
  //
  //   }catch(e){
  //     // debugPrint('Error creating user: $e');
  //     errorMessage = 'An error occurred.';
  //   }finally {
  //     isLoading = false;
  //   }
  // }

  Future<void> onRegisterWithPhoneApiCall(String fullName, String dateOfBirth, String preparingValue, String stateValue, List<String> preparingFor,
      String currentStatus, String phoneNumber, String email,String platform, {String? standardId, String? preparingId}) async {

    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try{
      final result = await _apiService.registerWithPhoneUsers(fullName, dateOfBirth, preparingValue, stateValue,
          preparingFor, currentStatus, phoneNumber, email,platform, standardId: standardId, preparingId: preparingId);
      signupWithPhone.value = result;
      if (result.created != null) {
        signupWithPhone.value = SignupWithPhoneModel(created: signupWithPhone.value?.created,
        data: signupWithPhone.value?.data);
      } else {
        signupWithPhone.value = SignupWithPhoneModel(err: signupWithPhone.value?.err);
      }

      if (signupWithPhone.value?.err?.code == 11000) {
        errorMessage = "Email already registered.";
      } else {
        errorMessage = signupWithPhone.value?.err?.message ?? '';
      }

    }catch(e){
      // debugPrint('Error creating user: $e');
      errorMessage = 'An error occurred.';
    }finally {
      isLoading = false;
    }
  }

  Future<void> onSendOtpToMail(String email, String fullname) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try{
      final result = await _apiService.sendOtpMail(email, fullname);
      errorMessageOtp.value = result;
      if (result.message != null) {
        errorMessageOtp.value = ErrorMessageModel(message: errorMessageOtp.value?.message);
      }else if(result.error != null){
        errorMessageOtp.value = ErrorMessageModel(error: errorMessageOtp.value?.error);
      }
    }catch(e){
      // debugPrint('Error creating user: $e');
      errorMessage = 'An error occurred.';
    }finally {
      isLoading = false;
    }
  }

  Future<void> onSendOtpToPhone(String phone,String email) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try{
      final result = await _apiService.sendOtpPhone(phone,email);
      
      // Check if the response contains error information
      if (result['code'] == 'ERROR_REGISTER_User' && result['params'] != null) {
        // Handle the "user previously deleted" error
        final params = result['params'] as Map<String, dynamic>;
        final message = result['message'] ?? 'User previously deleted.';
        final restoreUser = params['restoreUser'] ?? false;
        
        errorMessageOtp2.value = ErrorMessageModel(
          error: result['code'], 
          message: message
        );
        
        // Store additional info for handling restore functionality
        _restoreUserInfo = {
          'phone': params['phone'],
          'restoreUser': restoreUser,
          'message': message,
        };
      } else if (result['message'] != null) {
        // Success case
        errorMessageOtp2.value = ErrorMessageModel(message: result['message']);
      } else if (result['error'] != null) {
        // Other error cases
        errorMessageOtp2.value = ErrorMessageModel(error: result['error']);
      }
    }catch(e){
      // debugPrint('Error creating user: $e');
      errorMessage = 'An error occurred.';
    }finally {
      isLoading = false;
    }
  }

  Future<Map<String, dynamic>?> onCheckDeviceRegistration(String deviceUniqueId) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return null;
    }

    try{
      final result = await _apiService.checkDeviceRegistration(deviceUniqueId);
      return result;
    }catch(e){
      // debugPrint('Error checking device registration: $e');
      errorMessage = 'An error occurred while checking device registration.';
      return null;
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

  Future<void> onVerifyOtpToMail(String otp, String email) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    debugPrint("verifyApiStoreemail");
    isLoading = true;
    try{
      final result = await _apiService.verifyOtpWithMail(otp, email);
      registerWithEmail.value = result;
      if (result.message != null) {
        registerWithEmail.value = LoginWithPhoneModel(message: registerWithEmail.value?.message);
      } else {
        registerWithEmail.value = LoginWithPhoneModel(error: registerWithEmail.value?.error);
      }
    }catch(e){
      errorMessage = 'An error occurred.';
    }finally {
      isLoading = false;
    }
  }

  Future<void> onVerifyOtpToPhone(String phone, String otp) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }
    debugPrint("verifyApiStorephone");
    isLoading = true;
    try{
      final result = await _apiService.verifyOtpRegisterPhone(phone, otp);
      registerWithEmail2.value = result;
      if (result.message != null) {
        registerWithEmail2.value = LoginWithPhoneModel(message: registerWithEmail2.value?.message);
      } else {
        registerWithEmail2.value = LoginWithPhoneModel(error: registerWithEmail2.value?.error);
      }
    }catch(e){
      errorMessage = 'An error occurred.';
    }finally {
      isLoading = false;
    }
  }

  Future<void> onGetPreparingExams() async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try{
      final List<PreparingForModel> result = await _apiService.getPreparingExams();
      preparingexams.clear();
      preparingexams.addAll(result);
    } catch (e) {
      debugPrint('Error fetching preparingexams: $e');
      preparingexams.clear();
    } finally {
      isLoading = false;
    }
  }

  Future<void> onGetStandardsByPreparingId(String preparingId) async{
    await checkConnectionStatus();
    if (!isConnected) {
      return;
    }

    isLoading = true;
    try{
      final List<StandardModel> result = await _apiService.getStanderdByPreparing(preparingId);
      standardList.clear();
      standardList.addAll(result);
    } catch (e) {
      debugPrint('Error fetching standards by preparing id: $e');
      standardList.clear();
    } finally {
      isLoading = false;
    }
  }

}