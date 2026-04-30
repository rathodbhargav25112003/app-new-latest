import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../app/routes.dart';
import '../helpers/constants.dart';
import '../models/login_model.dart';
import '../models/signup_model.dart';
import '../models/strength_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../models/get_offers_model.dart';
import '../models/merit_list_model.dart';
import '../models/test_topic_model.dart';
import '../models/create_exam_model.dart';
import '../models/notes_topic_model.dart';
import '../models/report_list_model.dart';
import '../models/video_topic_model.dart';
import '../models/ask_question_model.dart';
import '../models/subscription_model.dart';
import '../models/error_message_model.dart';
import '../models/featured_list_model.dart';
import '../models/preparing_for_model.dart';
import '../models/standard_model.dart';
import '../models/searched_data_model.dart';
import '../models/test_category_model.dart';
import '../models/bookmark_topic_model.dart';
import '../models/notes_category_model.dart';
import '../models/practice_count_model.dart';
import '../models/video_category_model.dart';
import '../models/exam_paper_data_model.dart';
import '../models/forgot_password_model.dart';
import '../models/get_explanation_model.dart';
import '../models/subscribed_plan_model.dart';
import '../models/get_user_details_model.dart';
import '../models/login_with_phone_model.dart';
import '../models/question_pallete_model.dart';
import '../models/solution_reports_model.dart';
import '../models/test_subcategory_model.dart';
import '../models/user_exam_answer_model.dart';
import '../models/bookmark_category_model.dart';
import '../models/bookmark_mainlist_model.dart';
import '../models/create_query_mock_model.dart';
import '../models/get_settings_data_model.dart';
import '../models/notification_list_model.dart';
import '../models/signup_with_phone_model.dart';
import '../models/video_subcategory_model.dart';
import '../models/notes_subcategory_model.dart';
import '../models/bookmark_exam_list_model.dart';
import '../models/get_notes_solution_model.dart';
import '../models/notes_topic_detail_model.dart';
import '../models/report_by_category_model.dart';
import '../models/video_topic_detail_model.dart';
import '../models/get_all_coupon_user_model.dart';
import '../models/report_by_exam_list_model.dart';
import '../models/test_exampaper_list_model.dart';
import '../models/update_user_profile_model.dart';
import '../models/bookmark_by_examlist_model.dart';
import '../models/bookmark_subcategory_model.dart';
import '../models/create_video_history_model.dart';
import '../models/notes_topic_category_model.dart';
import '../models/video_topic_category_model.dart';
import '../modules/quiztest/model/quiz_model.dart';
import '../models/get_mock_test_details_model.dart';
import '../models/report_practice_count_model.dart';
import 'package:shusruta_lms/models/user_score.dart';
import '../models/get_all_my_custom_test_model.dart';
import '../models/payment_method_details_model.dart';
import '../models/question_pallete_count_model.dart';
import 'package:shusruta_lms/models/exam_report.dart';
import '../models/master_solution_reports_model.dart';
import '../models/get_report_by_topic_name_model.dart';
import '../models/update_bookmark_question_model.dart';
import 'package:shusruta_lms/models/mock_analysis.dart';
import 'package:shusruta_lms/models/mcq_exam_data.dart';
import '../models/create_subscription_order_model.dart';
import '../models/video_chapterization_list_model.dart';
import 'package:shusruta_lms/models/get_declaration.dart';
import '../models/create_query_solution_report_model.dart';
import 'package:shusruta_lms/models/BookmarkTestModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/exam_attempts_model.dart';
import 'package:shusruta_lms/models/login_with_wt_model.dart';
import '../modules/dashboard/models/global_search_model.dart';
import 'package:shusruta_lms/models/trend_analysis_model.dart';
import '../modules/quiztest/model/create_quiz_exam_model.dart';
import '../modules/quiztest/model/quiz_exam_answer_model.dart';
import '../modules/hardcopyNotes/model/get_all_book_model.dart';
import '../modules/quiztest/model/create_quiz_query_model.dart';
import '../modules/dashboard/models/progress_details_model.dart';
import '../modules/subscriptionplans/model/get_offer_model.dart';
import '../modules/dashboard/models/continue_watching_model.dart';
import '../modules/dashboard/models/homepage_watching_model.dart';
import '../modules/subscriptionplans/model/book_offer_model.dart';
import '../modules/quiztest/model/quiz_exam_paper_data_model.dart';
import '../modules/subscriptionplans/model/get_address_model.dart';
import '../modules/customtests/model/create_custom_exam_model.dart';
import '../modules/customtests/model/create_custom_test_model.dart';
import '../modules/quiztest/model/quiz_question_pallete_model.dart';
import '../modules/quiztest/model/quiz_solution_reports_model.dart';
import '../modules/quiztest/model/quiz_report_by_category_model.dart';
import '../modules/subscriptionplans/model/create_address_model.dart';
import 'package:shusruta_lms/modules/login/store/verify_otp_phone.dart';
import '../modules/customtests/model/custom_exam_paper_data_model.dart';
import '../modules/testimonial_and_blog/model/get_all_blogs_model.dart';
import '../modules/customtests/model/custom_question_pallete_model.dart';
import '../modules/customtests/model/user_custom_exam_answer_model.dart';
import '../modules/subscriptionplans/model/create_book_order_model.dart';
import '../modules/subscriptionplans/model/create_user_offer_model.dart';
import '../modules/customtests/model/create_custom_test_query_model.dart';
import '../modules/dashboard/models/create_video_note_history_model.dart';
import '../modules/quiztest/model/quiz_question_pallete_count_model.dart';
import '../modules/subscriptionplans/model/get_all_user_order_model.dart';
import '../modules/videolectures/model/get_video_quality_data_model.dart';
import '../modules/customtests/model/custom_test_exam_by_topic_model.dart';
import '../modules/testimonial_and_blog/model/get_blog_details_model.dart';
import 'package:shusruta_lms/models/test_exampaper_list_model.dart' as test;
import '../modules/customtests/model/custom_test_sub_by_category_model.dart';
import '../modules/testimonial_and_blog/model/create_testimonial_model.dart';
import '../modules/customtests/model/custom_test_solution_reports_model.dart';
import '../modules/videolectures/model/get_all_video_topic_detail_model.dart';
import '../modules/subscriptionplans/model/book_by_subscription_id_model.dart';
import '../modules/customtests/model/custom_test_report_by_category_model.dart';
import '../modules/customtests/model/custom_test_topic_by_subcategory_model.dart';
import 'package:shusruta_lms/modules/new_exam_component/model/exam_ans_model.dart';
import '../modules/testimonial_and_blog/model/get_all_testimonial_list_model.dart';
import '../modules/customtests/model/custom_test_question_pallete_count_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/get_section_list_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/create_section_exam_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/section_exam_paper_data_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/section_question_pallete_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/all_section_pallete_count_model.dart';
import '../modules/masterTest/sectionwisemasterTest/model/section_question_pallete_count_model.dart';
import '../modules/new_subscription_plans/model/plan_category_model.dart';
import '../modules/new_subscription_plans/model/plan_subcategory_model.dart';
import '../modules/hardcopyNotes/model/get_all_book_model.dart';
import '../modules/hardcopy/model/book_model.dart';
import '../modules/new_subscription_plans/model/coupon_model.dart';
import '../modules/new_subscription_plans/model/offer_model.dart';
import '../modules/new_subscription_plans/model/pincode_address_model.dart';
import '../modules/new_subscription_plans/model/all_plans_model.dart';

import 'dart:convert';
import '../services/secure_keys.dart';

class ApiService {
  Future<Map<String, String>> getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceId = '';
    String deviceName = '';
    String platform = '';

    if (Platform.isAndroid) {
      // Android specific device information
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      deviceName = androidInfo.model ?? 'Unknown';
      platform = 'Android';
    } else if (Platform.isIOS) {
      // iOS specific device information
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      deviceName = iosInfo.name ?? 'Unknown';
      platform = 'iOS';
    } else if (Platform.isMacOS) {
      // macOS specific device information
      final macInfo = await deviceInfo.macOsInfo;
      deviceId = macInfo.systemGUID ?? 'Unknown';
      deviceName = macInfo.model ?? 'Unknown';
      platform = 'macOS';
    } else if (Platform.isWindows) {
      // Windows specific device information
      final windowsInfo = await deviceInfo.windowsInfo;
      deviceId = windowsInfo.deviceId ?? 'Unknown';
      deviceName = windowsInfo.computerName ?? 'Unknown';
      platform = 'Windows';
    }
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    };
  }

  // Helper function to pretty print JSON response
  void printApiResponse(String apiName, http.Response response) {
    log('==================== $apiName ====================');
    log('Status Code: ${response.statusCode}');
    log('Headers: ${response.headers}');
    log('Request URL: ${response.request?.url}');
    log('------------------- Response Body -------------------');
    try {
      final dynamic jsonData = jsonDecode(response.body);
      const encoder = JsonEncoder.withIndent('  ');
      log(encoder.convert(jsonData));
    } catch (e) {
      log(response.body);
    }
    log('====================================================');
  }

  Future<SignupModel> registerUsers(
      String fullName,
      String dateOfBirth,
      String preparingValue,
      List<String> preparingFor,
      String currentStatus,
      String phoneNumber,
      String email,
      String password,
      String confirmPass,
      bool isGoogle) async {
    Map<String, dynamic> platformInfo = await getDeviceInfo();
    final response = await http.post(Uri.parse(userRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullName,
          'username': phoneNumber,
          'preparing_for': preparingValue,
          if (password.isNotEmpty) 'password': password,
          if (confirmPass.isNotEmpty) 'confirmPassword': confirmPass,
          'exams': preparingFor,
          'email': email,
          'date_of_birth': dateOfBirth,
          'current_data': currentStatus,
          'isSignInGoogle': isGoogle,
          'deviceUniqueId': platformInfo['device_id']
        }));

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SignupModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SignupModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<SignupWithPhoneModel> registerWithPhoneUsers(
      String fullName,
      String dateOfBirth,
      String preparingValue,
      String stateValue,
      List<String> preparingFor,
      String currentStatus,
      String phoneNumber,
      String email,
      String platform,
      {String? standardId, String? preparingId}) async {

      Map<String, dynamic> platformInfo = await getDeviceInfo();
      final response = await http.post(Uri.parse(userRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullname': fullName,
          'username': phoneNumber,
          'preparing_for': preparingValue,
          'standerd_for': preparingFor.isNotEmpty ? preparingFor[0] : '',
          'state': stateValue,
          // if(password.isNotEmpty) 'password': password,
          // if(confirmPass.isNotEmpty) 'confirmPassword': confirmPass,
          // 'exams': preparingFor,
          'email': email,
          'date_of_birth': dateOfBirth,
          'current_data': currentStatus,
          "deviceType": platform == "tab" ? "tab" : platformInfo['platform'],
          "deviceName": platformInfo['device_name'],
          "deviceId": platformInfo['device_id'],
          "deviceUniqueId": platformInfo['device_id'],
          if (standardId != null) 'standerd_id': standardId,
          if (preparingId != null) 'preparing_id': preparingId,
        }));
        debugPrint("request body registerWithPhoneUsers ${response.body}");
    log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SignupWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SignupWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> clearNotification() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.delete(
      Uri.parse(clearNotifications),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    if (response.statusCode == 200) {
      log('successfully clear notification');
    } else if (response.statusCode == 500) {
      log('successfully clear notification');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> deteledAccount(String userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.delete(
      Uri.parse("$deleteAccount/$userId"),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    if (response.statusCode == 200) {
      log('successfully deleted Account');
    } else if (response.statusCode == 500) {
      log('successfully deleted Account');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginModel> loginUsers(String email, String password) async {
    final response = await http.post(Uri.parse(userLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetDeclaration> getDeclaration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
      Uri.parse(getDeclarationTest),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetDeclaration.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithWtModel> loginWtUsers(String phone, String deviceType) async {
    final response = await http.post(Uri.parse(userLoginwithWt),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phone": phone, "deviceType": deviceType}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithWtModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithWtModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithWtModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithWtModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ErrorMessageModel> sendOtpMail(String email, String fullname) async {
    final response = await http.post(Uri.parse(sendOtpToMail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "fullname": fullname}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ErrorMessageModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ErrorMessageModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> sendOtpPhone(String phone, String email) async {
    final response = await http.post(Uri.parse(sendOtpToPhone),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "phone": phone,
          'email': email,
        }));

    debugPrint("response body ${response.body}");
    debugPrint("response code ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> restoreUserAccount(String email, String phone) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      final response = await http.put(Uri.parse(restoreUser),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token ?? '',
          },
          body: jsonEncode({
            "email": email,
            "phone": phone,
          }));

      debugPrint("restoreUser response body ${response.body}");
      debugPrint("restoreUser response code ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return jsonData;
      } else {
        throw Exception('Failed to restore user');
      }
    } catch (e) {
      debugPrint('Error restoring user: $e');
      throw Exception('Failed to restore user: $e');
    }
  }

  Future<Map<String, dynamic>> sendOtpToForgotEmail(String email) async {
    final response = await http.post(Uri.parse(sendOtpToForgotMail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}));

    log("response ${response.body}");
    debugPrint("response body ${response.body}");
    debugPrint("response code ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithPhoneModel> verifyForgotOtpWithMail(
      String email, String otp) async {
    final response = await http.post(Uri.parse(verifyforgotpassOtpMail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userOTP': otp, "email": email}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ForgotPasswordModel> forgotPasswithMail(
      String pass, String confirmPass, String email) async {
    final response = await http.post(Uri.parse(forgotPass),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newPassword': pass,
          'confirmPassword': confirmPass,
          'email': email
        }));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ForgotPasswordModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ForgotPasswordModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithPhoneModel> verifyOtpWithMail(
      String otp, String email) async {
    final response = await http.post(Uri.parse(verifyOtpMail),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userOTP': otp, "email": email}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithPhoneModel> verifyOtp(
      String phone, String otp, String loggedInPlatform) async {
    // log('devPlat$loggedInPlatform');
    Map<String, dynamic> platformInfo = await getDeviceInfo();
    final response = await http.post(Uri.parse(userLoginVerifyOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": phone,
          // "phone": phone,
          "userOTP": otp,
          "deviceType":
              loggedInPlatform == "tab" ? "tab" : platformInfo['platform'],
          "deviceName": platformInfo['device_name'],
          "deviceId": platformInfo['device_id'],
          "deviceUniqueId": platformInfo['device_id']
        }));

    log("response emailotp ${response.body}");
    log("response statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithPhoneModel> verifyOtpPhone(String phone, String otp,
      String deviceId, String deviceName, String deviceType) async {
    final response = await http.post(Uri.parse(userLoginVerifyOtp2),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        // "email": phone,
        "phone": phone,
        "userOTP": otp,
        "deviceType": deviceType,
        "deviceName": deviceName,
        "deviceId": deviceId,
        "deviceUniqueId": deviceId
      }));

    log("response phoneotp ${response.body}");
    log("response statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<Map<String, dynamic>> deleteDeviceInfo(String id, String token,
      String deviceId, String deviceName, String deviceType) async {
    final response = await http.post(Uri.parse(deleteLoggedInDevice),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          "deviceId": id,
          "newDeviceId": deviceId,
          "deviceType": deviceType,
          "deviceName": deviceName,
        }));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to delete device');
    }
  }

  Future<Map<String, dynamic>> checkDeviceInfo(String id, String token) async {
    log("token:$token");
    final response = await http.post(Uri.parse(checkDeviceExists),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({"deviceId": id}));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to delete device');
    }
  }

  Future<Map<String, dynamic>> checkDeviceRegistration(String deviceUniqueId) async {
    log("deviceUniqueId:$deviceUniqueId");
    final response = await http.post(Uri.parse(checkDevice),
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiI2NGNiODU0NzcyODMxMWI3NzczNWFlN2M6MDRIZkdjTVkiLCJpYXQiOjE2OTE3MzY4MTl9.UDS05vF55khbzs554r3SX1Sj4ac5jxN1320G6Ulj_NA',
        },
        body: jsonEncode({"deviceUniqueId": deviceUniqueId}));
        debugPrint("response body: ${response.body}");
        debugPrint("response statusCode: ${response.statusCode}");
      
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to check device registration');
    }
  }

  Future<LoginWithPhoneModel> verifyOtpRegisterPhone(
      String phone, String otp) async {
    final response = await http.post(Uri.parse(userRegisterOtp2),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // "email": phone,
          "phone": phone,
          "userOTP": otp,
          // "deviceType": loggedInPlatform
        }));

    log("response phoneotp ${response.body}");
    log("response statusCode ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 404) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginWithPhoneModel> loginWithPhoneUsers(String phone) async {
    final response = await http.post(Uri.parse(userLoginWithWtPhone),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // "phoneNumber": phone,
          "phone": phone,
        }));

    debugPrint("response body ${response.body}");
    debugPrint("response code ${response.statusCode}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginWithPhoneModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // Handle ERROR_REGISTER_User case
      if (jsonData['code'] == 'ERROR_REGISTER_User') {
        // Create ErrorModel using the structure expected
        final errorModelData = {
          'code': jsonData['code'],
          'message': jsonData['message'],
          'params': jsonData['params'],
        };
        // Use the full model structure to avoid ambiguity
        final loginModelData = {
          'err': errorModelData,
        };
        return LoginWithPhoneModel.fromJson(loginModelData);
      }
      return LoginWithPhoneModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<LoginModel> loginWithGoogleUsers(String email) async {
    final response = await http.post(Uri.parse(userGoogleLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}));

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return LoginModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> createNotificationToken(String fcmToken) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createNotification),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({"fcm_token": fcmToken}));

    log("response fcmtoken create${response.body}");
    if (response.statusCode == 201) {
      log("fcm token success");
    } else if (response.statusCode == 500) {
      log("fcm token failed");
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> deleteNotificationToken(String fcmToken) async {
    final response = await http.delete(Uri.parse(deleteNotification),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"fcm_token": fcmToken}));

    log("response fcmtoken delete${response.body}");
    if (response.statusCode == 200) {
      log("fcm token success delete");
    } else if (response.statusCode == 500) {
      log("fcm token failed");
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> signoutUser(String loggedInPlatform) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) {
      log("No token available for logout");
      return;
    }
    final response = await http.post(Uri.parse(logoutUser),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
        body: jsonEncode({"deviceType": loggedInPlatform}));

    log("response log out user ${response.body}");
    if (response.statusCode == 200) {
      log("signout success");
    } else if (response.statusCode == 500) {
      log("signout failed");
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> signoutUserAllDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) {
      log("No token available for logout all devices");
      return;
    }
    final response = await http.get(
      Uri.parse(logoutUserAllDevice),
      headers: {'Content-Type': 'application/json', 'Authorization': token},
    );

    log("response log out user all device ${response.body}");
    if (response.statusCode == 200) {
      log("signout all device success");
    } else if (response.statusCode == 500) {
      log("signout all device failed");
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SubscriptionModel>> subscriptionPlan(
      bool neetSS, bool iniss) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token : $token");

    final response = await http.get(
      Uri.parse("$subscriptionsPlan?Neet_SS=$neetSS&INISS_ET=$iniss"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token!,
      },
    );

    log("response of subscription plan ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);

      // Map JSON to SubscriptionModel and apply filter
      List<SubscriptionModel> subscriptionList = jsonData
          .map((item) => SubscriptionModel.fromJson(item))
          .where((subscription) =>
              !(subscription.duration?.any((e) => e.price == 0) ?? false))
          .toList();

      return subscriptionList;
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateSubscriptionOrderModel> purchaseSubscriptionPlan(
      String subscriptionId,
      int price,
      String day,
      String durationId,
      String paymentId,
      String razorpayOrderId,
      String razorpaySignature,
      String couponId,
      String offerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> requestBody = {
      'subscription_id': subscriptionId,
      'amount': price,
      'day': int.parse(day),
      'duration_id': durationId,
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
      'coupon_id': couponId,
      'offer_id': offerId,
    };

    final response = await http.post(Uri.parse(createSubscriptionsPlan),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(requestBody));

    // print('Request Body: ${jsonEncode(requestBody)}');
    // log("response ${response.body}");

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSubscriptionOrderModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSubscriptionOrderModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateSubscriptionOrderModel> purchaseFixedSubscriptionPlan(
      String subscriptionId,
      int price,
      bool addFixedValidity,
      String paymentId,
      String razorpayOrderId,
      String razorpaySignature,
      String couponId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> requestBody = {
      'subscription_id': subscriptionId,
      'amount': price,
      'addFixedValidity': addFixedValidity,
      'razorpay_payment_id': paymentId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_signature': razorpaySignature,
      'coupon_id': couponId,
    };

    final response = await http.post(Uri.parse(createFixedSubscriptionsPlan),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(requestBody));

    // print('Request Body: ${jsonEncode(requestBody)}');
    // log("response ${response.body}");

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSubscriptionOrderModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSubscriptionOrderModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateUserOfferModel> createUserOffer(String offerId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> requestBody = {
      'offer_id': offerId,
    };

    final response = await http.post(Uri.parse(createOfferByUser),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(requestBody));

    log("response createUserOffer ${response.body}");

    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateUserOfferModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateUserOfferModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CreateBookOrderModel>> purchaseBookOrder(
      String addressId, List prize, List bookId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> requestBody = {
      'Book_id': bookId,
      'Address_id': addressId,
      'Price': prize,
    };

    final response = await http.post(Uri.parse(createBookOrder),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(requestBody));

    // print('Request Body: ${jsonEncode(requestBody)}');
    log("response create book order ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CreateBookOrderModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CreateBookOrderModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ContinueWatchingModel>> getContinueHistoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getWatchingHistory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getContinueHistoryList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ContinueWatchingModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ContinueWatchingModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<HomePageWatchingModel>> getHomePageHistoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getHomePageHistory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getHomePageHistoryList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => HomePageWatchingModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => HomePageWatchingModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> createContinueHistoryTest(String examId, String testType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("examId:$examId");
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "mockExam_id": examId,
      "exam_id": examId,
      "test_type": testType,
    };
    final response = await http.post(Uri.parse(createWatchingHistoryTest),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of createContinueHistoryTest ${response.body}");
    if (response.statusCode == 201) {
      log("successfully create 201");
    } else if (response.statusCode == 200) {
      log("successfully create 200");
    } else if (response.statusCode == 500) {
      log("successfully create 500");
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateVideoNoteHistoryModel> createContinueHistoryVideoNote(
      String contentId, String contentType) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "content_id": contentId,
      "content_type": contentType,
    };
    final response = await http.post(Uri.parse(createWatchingHistoryVideoNote),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of createContinueHistoryVideoNote ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoNoteHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoNoteHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoNoteHistoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoCategoryModel>> videoCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(videoCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response videoCat ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoSubCategoryModel>> videoSubCategoryList(String vid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$videoSubCategory/$vid"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoTopicCategoryModel>> videoTopicCategoryList(
      String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$videoTopicCategory/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response videoTopicCategoryList${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoTopicCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoTopicCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoTopicModel>> videoTopicList(String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$videoTopic/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    debugPrint("response videoTopicList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoTopicModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoTopicDetailModel>> videoTopicDetailList(
      String topicId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$videoTopicDetail/$topicId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response videoTopicDetail:${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoTopicDetailModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoTopicDetailModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoChapterizationListModel>> videoChapterizationList(
      String videoId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$videoChapterizationData/$videoId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response videoChapterizationData:${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoChapterizationListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoChapterizationListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch chapterization');
    }
  }

  Future<GetAllVideoTopicDetailModel> getAllVideoTopicDetailList(
      String topicId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$getAllVideoBytopicId/$topicId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllVideoTopicDetailList $topicId${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetAllVideoTopicDetailModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetAllVideoTopicDetailModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetVideoQualityDataModel> getVideoQualityDetail(String videoId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$getVimeoVideoData/$videoId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getVimeoVideoData $videoId${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetVideoQualityDataModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetVideoQualityDataModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> videoProgressTime(
      String contentId, String? pausedTime, int? pageNo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "content_id": contentId,
      if (pausedTime != "") "time": pausedTime,
      if (pageNo != 0) "pageNumber": pageNo,
    };
    debugPrint("params$params");
    final response = await http.post(Uri.parse(videoContentProgress),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));

    debugPrint("response ${response.body}");
    if (response.statusCode == 201) {
      debugPrint('successfully saved video progress');
    } else if (response.statusCode == 500) {
      debugPrint('unsuccessful save video progress');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateVideoHistoryModel> createMarkAsCompleted(
      String contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "content_id": contentId,
    };
    final response = await http.post(Uri.parse(markAsCompleted),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of createMarkAsCompleted ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateVideoHistoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> createBookMarkContent(String contentId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "content_id": contentId,
    };
    final response = await http.post(Uri.parse(bookmarkContent),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    debugPrint("response of content Bookmark ${response.body}");
    if (response.statusCode == 201) {
      debugPrint("bookmark done 201");
      // final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // return CreateVideoHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 200) {
      debugPrint("bookmark done 200");
      // final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // return CreateVideoHistoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      debugPrint("create bookmark 500");
      // final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // return CreateVideoHistoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CustomTestModel> createCustomTest(
      String testName,
      String description,
      int numberOfQuestion,
      String timeDuration,
      List<Map<String, dynamic>> category,
      List<Map<String, dynamic>> subCategory,
      List<Map<String, dynamic>> topic,
      List<Map<String, dynamic>> exam) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "testName": testName,
      "Description": description,
      "NumberOfQuestions": numberOfQuestion,
      "time_duration": timeDuration,
      "category": category,
      "subcategory": subCategory,
      "topic": topic,
      "exam": exam,
    };
    final response = await http.post(Uri.parse(createCustomTestUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of create custom test ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuizModel> getTodayQuizDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getTodayQuiz),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getTodayQuizData${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> deleteCustomTest(String customTestId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.delete(
      Uri.parse("$deleteCustomTestUrl/$customTestId"),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    if (response.statusCode == 200) {
      log('successfully deleted Custom Test');
    } else if (response.statusCode == 500) {
      log('successfully deleted Custom Test');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<MyCustomTestListModel> customTestList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(getAllMyCustomTest),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return MyCustomTestListModel.fromJson(jsonData);
    } else if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return MyCustomTestListModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return MyCustomTestListModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestSubByCategoryModel>> customTestSubByCategoryList(
      String cateIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(
        Uri.parse("$customTestSubByCateId?id=$cateIds"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response customTestSubCategoryList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestSubByCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestSubByCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestTopicBySubCategoryModel>>
      customTestTopicBySubCategoryList(String subIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(
        Uri.parse("$customTestTopicBySubId?id=$subIds"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response customTestSubCategoryList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestTopicBySubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestTopicBySubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestExamByTopicModel>> customTestExamByTopicList(
      String topicIds) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(
        Uri.parse("$customTestExamByTopicId?id=$topicIds"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response customTestSubCategoryList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestExamByTopicModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestExamByTopicModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestCategoryModel>> testCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(testCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestCategoryModel>> customTestCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(customTestCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestCategoryModel>> allTestCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(getAllTestCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("responseAllTest ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestCategoryModel>> cateWiseTestCategoryList(
      bool neetSS, bool iniss) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(
        Uri.parse("$getAllTestCategoryByType?Neet_SS=$neetSS&INISS_ET=$iniss"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("url${"$getAllTestCategoryByType?Neet_SS=$neetSS&INISS_ET=$iniss"}");
    log("responseAllTest ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestCategoryModel>> getLeaderBoardCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(getLeaderBoardCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestSubCategoryModel>> testSubCategoryList(String testid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$testSubCategory/$testid"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => TestSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => TestSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<bool> freePlanApiCall(String planId, int day) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createFreeTrail),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({"plan_id": planId, "day": day}));
    debugPrint("planId $planId");
    debugPrint("day $day");
    debugPrint("response ${response.body}");
    debugPrint("response status code ${response.statusCode}");
    if (response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 500) {
      return false;
    } else {
      throw Exception('Failed to freePlanApiCall');
    }
  }

  Future<List<TestTopicModel>> testTopicList(String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$testTopic/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData.map((item) => TestTopicModel.fromJson(item)).toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [TestTopicModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TestTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> examQuestionPaperData(String examId) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$testExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> practiceExamQuestionPaperData(
      String examId) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$practiceTestExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> examPracticeQuestionPaperData(
      String examId, String type) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$testPracticeExamPaperData/$examId?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response examPracticeQuestionPaperData${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> mockExamPracticeQuestionPaperData(
      String examId, String type) async {
    log('examapistoreexassm');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$testMockPracticeExamPaperData/$examId?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response mockExamPracticeQuestionPaperData${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> customExamPracticeQuestionPaperData(
      String examId, String type) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$customTestPracticeExamPaperData/$examId?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response customExamPracticeQuestionPaperData${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomExamPaperDataModel>> customExamQuestionPaperData(
      String examId) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$testCustomExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomExamPaperDataModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomExamPaperDataModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<QuizExamPaperDataModel>> quizExamQuestionPaperData(
      String examId) async {
    log('examapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$quizExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizExamPaperDataModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizExamPaperDataModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> materExamQuestionPaperData(
      String examId) async {
    log('examapistoreexamss');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$testMaterExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ExamPaperDataModel>> masterPracticeExamQuestionPaperData(
      String examId) async {
    log('practiceexamapistoreexam');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$practiceTestMaterExamPaperData/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ExamPaperDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SectionExamPaperDataModel>> sectionExamQuestionPaperData(
      String examId, String sectionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$testSectionExamPaperData/$examId/$sectionId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response sectionExamQuestionPaperData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SectionExamPaperDataModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SectionExamPaperDataModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesCategoryModel>> notesCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(notesCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => NotesCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => NotesCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesSubCategoryModel>> notesSubCategoryList(
      String notesid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$notesSubCategory/$notesid"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesTopicCategoryModel>> notesTopicCategoryList(
      String notesid) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$notesTopicCategory/$notesid"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesTopicCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesTopicCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesTopicModel>> notesTopicList(String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$notesTopic/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData.map((item) => NotesTopicModel.fromJson(item)).toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [NotesTopicModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => NotesTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<NotesTopicDetailModel> notesTopicDetailList(String topicId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$notesTopicDetail/$topicId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response notestopicdetail${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return NotesTopicDetailModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return NotesTopicDetailModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkCategoryModel>> bookMarkCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(bookmarkCategoryList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      log("token$jsonData");
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkCategoryModel>> masterBookMarkCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(masterBookmarkCategoryList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkSubCategoryModel>> bookMarkSubCategoryList(
      String catId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("$bookmarkSubCategoryList/$catId");
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$bookmarkSubCategoryList/$catId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkSubCategoryModel>> bookMarkSubCategoryListv2(
      List<String> catIds, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$bookmarkCustomeSubCategoryList").replace(queryParameters: {
          'id':
              catIds, // List<String> directly works with queryParameters in Dart
          'type': type,
        }),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkTopicModel>> bookMarkTopicList(String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$bookmarkTopicList/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkTopicModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkTopicModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => BookMarkTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkTopicModel>> bookMarkTopicListv2(
      List<String> ids, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$bookmarkTopicListv2").replace(queryParameters: {
          'id': ids, // List<String> directly works with queryParameters in Dart
          'type': type,
        }),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkTopicModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkTopicModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => BookMarkTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetExplanationModel> getExplanation(String prompt) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "prompt": prompt,
    };
    final response = await http.post(Uri.parse(getexplanation),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of getExplanation ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetExplanationModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetExplanationModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<AskQuestionModel> createChatBotQuestion(
      String question, String answer) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "question": question,
      "answer": answer,
    };
    final response = await http.post(Uri.parse(createAskQuestion),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of createChatBotQuestion ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return AskQuestionModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return AskQuestionModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<AskQuestionModel>> getAllAskQuestion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
      Uri.parse(getAskQuestion),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );
    log("response of getAllAskQuestion ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => AskQuestionModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => AskQuestionModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> deleteAllAskQuestion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse(deleteAskQuestion),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    if (response.statusCode == 201) {
      log('successfully deleted AskQuestion');
    } else if (response.statusCode == 500) {
      log('unsuccessful delete AskQuestion');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkCategoryModel>> reportCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(reportListByCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkCategoryModel>> masterReportCategoryList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("token$token");
    final response = await http.get(Uri.parse(masterreportListByCategory),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkSubCategoryModel>> reportSubCategoryList(
      String catId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$reportListBySubCategory/$catId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkTopicModel>> reportTopicList(String subCatId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$reportListByTopic/$subCatId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkTopicModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkTopicModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => BookMarkTopicModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<UserScore>> getUserScoreById(String examId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$userScore/$examId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      return parseUserScores(jsonData);
    } else {
      throw Exception('Failed to fetch users score');
    }
  }

  Future<List<TestExamPaperListModel>> testExamByCategoryList(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('tokentest$token');
    log('id$id');
    String url = testExamByCategory;
    if (type == "category") {
      url = testExamByCategory;
    } else if (type == "subcategory") {
      url = testExamBySubCategory;
    } else if (type == "topic") {
      url = testExamByTopic;
    }

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => TestExamPaperListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [TestExamPaperListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => TestExamPaperListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestExamPaperListModel>> allTestExamByCategoryList(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('tokentest$token');
    log('id$id');
    String url = getAllTest;

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllTest$url");
    log("response getAllTest${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => TestExamPaperListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [TestExamPaperListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => TestExamPaperListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ExamAttemptsModel> allExamAttemptList(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('tokentest$token');
    log('id$id');
    String url = getUserAttemptList;

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    printApiResponse('allExamAttemptList', response);
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      return ExamAttemptsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<McqExamData> allMcqExamAttemptList(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('id$id');
    String url = getMcqUserTestList;
    log("$url/$id");

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    printApiResponse('allMcqExamAttemptList', response);
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      return McqExamData.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TestExamPaperListModel>> allLeaderboardTestExamByCategoryList(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('tokentest$token');
    log('id$id');
    String url = getAllLeaderboardTest;

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllTest${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => TestExamPaperListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [TestExamPaperListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => TestExamPaperListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<TrendAnalysisModel>> getTrendAnalysis(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = getAllTrendAnalysis;

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllTrendAnalysis${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => TrendAnalysisModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [TrendAnalysisModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => TrendAnalysisModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch getTrendAnalysis');
    }
  }

  Future<List<ReportByExamListModel>> reportExamByCategoryList(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = reportsByTestCategory;
    if (type == "category") {
      url = reportsByTestCategory;
    } else if (type == "subcategory") {
      url = reportsByTestSubCategory;
    } else if (type == "topic") {
      url = reportsByTestTopic;
    }

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response reportExamByCategoryList${response.body}");
    log(response.body.toString());
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => ReportByExamListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [ReportByExamListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ReportByExamListModel>> masterReportExamByCategoryList(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$masterReportsByTestCategory/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    log("response ${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => ReportByExamListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [ReportByExamListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ReportByCategoryModel>> reportsListByType(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = reportCategoryNewChange;
    // if(type=="category"){
    //   url=reportsCategory;
    // }else if(type=="subcategory"){
    //   url=reportsSubCategory;
    // }else if(type=="topic"){
    //   url=reportsTopic;
    // }
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response category${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestReportByCategoryModel>> customTestReportsByCategory(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = customTestReportByCategory;
    // if(type=="category"){
    //   url=reportsCategory;
    // }else if(type=="subcategory"){
    //   url=reportsSubCategory;
    // }else if(type=="topic"){
    //   url=reportsTopic;
    // }
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response category${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestReportByCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestReportByCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ReportByTopicNameModel>> reportsListByTopicName(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$reportsTopicName/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByTopicNameModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByTopicNameModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ReportSrengthModel> reportsListByStregthTopicName(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("Strength id $id");
    final response = await http.get(Uri.parse("$reportByStegthTopic$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    print("response from stregth data ${response.body}");
    // if (response.statusCode == 200) {
    //   final List<dynamic> jsonData = jsonDecode(response.body);
    //   return jsonData.map((item) => ReportSrengthModel.fromJson(item)).toList();
    // } else if(response.statusCode == 500){
    //   final List<dynamic> jsonData = jsonDecode(response.body);
    //   return jsonData.map((item) => ReportSrengthModel.fromJson(item)).toList();
    // } else {
    //   throw Exception('Failed to fetch users');
    // }
    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportSrengthModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<PracticeCountModel> getQuestionCountForPractice(
      String id, String type, bool isCustom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(type);

    String dataType =
        type == "MockBookmark" ? "MockPracticeBookmark" : "McqPracticeBookmark";
    if (type == "McqBookmark" || type == "MockBookmark" || isCustom) {
      print("$getCustomCountTestMode/$id?type=$dataType");
    } else {
      print("$getQuestionCountPractice/$id?type=$type");
    }
    final response = await http.get(
        Uri.parse(type == "McqBookmark" || type == "MockBookmark" || isCustom
            ? isCustom
                ? "$getCustomCountTestMode/$id?type=CustomPractice"
                : "$getCustomCountTestMode/$id?type=$dataType"
            : "$getQuestionCountPractice/$id?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getQuestionCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return PracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getNeetPrediction(String marks) async {
    final response = await http.post(Uri.parse(getNEETPrediction),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"total_marks": marks}));

    print("response from getNeetPrediction ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<PracticeCountModel> getMockQuestionCountForPractice(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getMockQuestionCountPractice/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getMockQuestionCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return PracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<PracticeCountModel> getCustomQuestionCountForPractice(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getCustomQuestionCountPractice/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getCustomQuestionCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return PracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<ReportPracticeCountModel> getReportCountForPractice(
      String id, String type, bool isCustom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(type);
    if (type == "McqBookmark" || type == "MockBookmark") {
      print("$getBookmarkPracticeReport/$id?type=$type");
    } else if (isCustom) {
      print("$getCustomPracticeReport/$id?type=$type");
    } else {
      print("$getCountPracticeReport/$id");
    }
    final response = await http.get(
        Uri.parse(isCustom
            ? "$getCustomPracticeReport/$id?type=$type"
            : type == "McqBookmark" || type == "MockBookmark"
                ? "$getBookmarkPracticeReport/$id?type=$type"
                : "$getCountPracticeReport/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getReportCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportPracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<ReportPracticeCountModel> getMockReportCountForPractice(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getMockCountPracticeReport/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getReportCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportPracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<ReportPracticeCountModel> getCustomReportCountForPractice(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getCustomCountPracticeReport/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    print("response from getReportCountForPractice ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportPracticeCountModel.fromJson(jsonData);
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<List<ReportByCategoryModel>> masterReportsListByType(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = solutionMasterReportCategory;
    // if(type=="category"){
    //   url=reportsCategory;
    // }else if(type=="subcategory"){
    //   url=reportsSubCategory;
    // }else if(type=="topic"){
    //   url=reportsTopic;
    // }
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => ReportByCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<ReportListModel>> reportsListAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(reportsList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ReportListModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => ReportListModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetSectionListModel>> getSectionLists(
      String examId, String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSectionTestList/$examId/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getSectionLists ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetSectionListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetSectionListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateCustomExamModel> startCustomExamTest(
      String examId, String startTime, String endTime, bool? isPractice) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createCustomExam),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'customTest_id': examId,
          'start_time': startTime,
          'end_time': endTime,
          'isPractice': isPractice
        }));

    // log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateCustomExamModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateCustomExamModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateExamModel> startExamTest(String examId, String startTime,
      String endTime, bool? isPractice, String type, String? userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createExam),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'exam_id': examId,
          'userExamType':
              type.isEmpty || type == "topic" ? "All Questions" : type,
          "mainUserExam_id": userExamId,
          'start_time': startTime,
          'end_time': endTime,
          'isPractice': isPractice
        }));

    log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateExamModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateExamModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateQuizExamModel> startQuizExamTest(
      String examId, String startTime, String endTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createQuizExam),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'quiz_id': examId,
          'start_time': startTime,
          'end_time': endTime,
        }));

    log("response startQuizExamTest${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuizExamModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuizExamModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateExamModel> startMasterExamTest(
      String examId, String startTime, String endTime, bool? isPractice) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createMasterExam),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'exam_id': examId,
          'start_time': startTime,
          'end_time': endTime,
          'isPractice': isPractice
        }));

    log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateExamModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateExamModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateSectionExamModel> startSectionMasterExamTest(
      String userExamId, String sectionId, String status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createSectionMasterExam),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'userExam_id': userExamId,
          'section_id': sectionId,
          'status': status,
        }));

    log("response startSectionMasterExamTest ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSectionExamModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateSectionExamModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<UserExamAnswer> userAnswerExamTest(
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(userAnswer),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'userExam_id': userExamId,
          'question_id': questionId,
          'selected_option': selectedOption,
          'attempted': isAttempted,
          'attempted_marked_for_review': isAttemptedAndMarkedForReview,
          'skipped': isSkipped,
          'guess': guess,
          'marked_for_review': isMarkedForReview,
          'time': time
        }));

    log("response12122001 ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuizExamAnswer> userAnswerQuizExamTest(
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(userQuizAnswer),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'quizUserExam_id': userExamId,
          'quizQuestion_id': questionId,
          'selected_option': selectedOption,
          'attempted': isAttempted,
          'attempted_marked_for_review': isAttemptedAndMarkedForReview,
          'skipped': isSkipped,
          'guess': guess,
          'marked_for_review': isMarkedForReview,
          'time': time
        }));

    log("response12122001 ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<UserCustomExamAnswer> userAnswerExamCustomTest(
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(userCustomAnswer),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'customUserExam_id': userExamId,
          'question_id': questionId,
          'selected_option': selectedOption,
          'attempted': isAttempted,
          'attempted_marked_for_review': isAttemptedAndMarkedForReview,
          'skipped': isSkipped,
          'guess': guess,
          'marked_for_review': isMarkedForReview,
          'time': time
        }));

    log("response12122001 ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserCustomExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserCustomExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<UserExamAnswer> userAnswerMasterExamTest(
      String userExamId,
      String questionId,
      String selectedOption,
      bool isAttempted,
      bool isAttemptedAndMarkedForReview,
      bool isSkipped,
      bool isMarkedForReview,
      String guess,
      String time,
      String? questionTime) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(userAnswerMaster),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'userExam_id': userExamId,
          'question_id': questionId,
          'selected_option': selectedOption,
          'attempted': isAttempted,
          'attempted_marked_for_review': isAttemptedAndMarkedForReview,
          'skipped': isSkipped,
          'guess': guess,
          'marked_for_review': isMarkedForReview,
          'time': time,
          'timePerQuestion': questionTime
        }));

    log("master exam ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ReportByCategoryModel> reportsByExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$testReportByExamV2/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response report ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportByCategoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportByCategoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ExamReport> examReport(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("$examReports/$id");
    final response = await http.get(Uri.parse("$examReports/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("Exam report ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ExamReport.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ExamReport.fromJson(jsonData);
    } else {
      throw Exception('Failed to ExamReport');
    }
  }

  Future<McqAnalysis> mcqExamReport(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("$getMcqAnalysis/$id");
    final response = await http.get(Uri.parse("$getMcqAnalysis/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("McqAnalysis ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return McqAnalysis.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return McqAnalysis.fromJson(jsonData);
    } else {
      throw Exception('Failed to McqAnalysis');
    }
  }

  Future<McqAnalysis> bookmarkExamReport(String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("$getCustomAnalysis/$id?${type}");
    final response = await http.get(
        Uri.parse("$getCustomAnalysis/$id?type=${type}"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("getCustomAnalysis ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return McqAnalysis.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return McqAnalysis.fromJson(jsonData);
    } else {
      throw Exception('Failed to McqAnalysis');
    }
  }

  Future<Map<String, dynamic>> getCountTestMcqMode(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (type == "") {
      print("$getCountTestMode/$id");
    } else {
      print("$getCustomCountTestMode/$id?type=$type");
    }
    final response = await http.get(
        Uri.parse(type == ""
            ? "$getCountTestMode/$id"
            : "$getCustomCountTestMode/$id?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("getCountTestMcqMode ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to getCountTestMcqMode');
    }
  }

  Future<ExamReport> examReportRank1(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$examReportsRank1/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("Exam examReportRank1 ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ExamReport.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ExamReport.fromJson(jsonData);
    } else {
      throw Exception('Failed to examReportRank1');
    }
  }

  Future<QuizReportByCategoryModel> reportsByQuizExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$quizTestReportByExam/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response report ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizReportByCategoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizReportByCategoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CustomTestReportByCategoryModel> reportsByCustomTestExam(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$customTestReportByExam/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response custom report $id ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestReportByCategoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestReportByCategoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ReportByCategoryModel> reportsByMasterExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$masterTestReportByExam/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportByCategoryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ReportByCategoryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  /// Bookmark////
  Future<BookmarkTestModel> getAllMyCustomTestBookmark(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getAllMyCustomTestBookmarkApi?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return BookmarkTestModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to getAllMyCustomTestBookmark');
    }
  }

  Future<void> getBookmarkSubcategoryList(String type, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getBookmarkSubcategoryListApi?type=$type&id=$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
    } else {
      throw Exception('Failed to getAllMyCustomTestBookmark');
    }
  }

  Future<List<test.TestData>> getBookmarkMacqQuestionList(
      String type, String id, bool isAll, bool isMock, bool isCustom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(isMock
        ? "$getBookmarkMockQuestionListApi$id?type=$type&isAll=${isAll.toString()}"
        : "$getBookmarkMCQQuestionListApi$id?type=$type&isAll=${isAll.toString()}");
    final response = await http.get(
        Uri.parse(isCustom
            ? "$getCustomeQuestionListApi$id?type=$type&isAll=${isAll.toString()}"
            : isMock
                ? "$getBookmarkMockQuestionListApi$id?type=$type&isAll=${isAll.toString()}"
                : "$getBookmarkMCQQuestionListApi$id?type=$type&isAll=${isAll.toString()}"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to getMcqExamQuestionList');
    }
  }

  Future<List<test.TestData>> getCustomMacqQuestionList(
      String type, String id, bool isCustom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(id);
    print(type);
    print("$getCustomeMcqListApi$id?type=$type");
    final response = await http.get(
        Uri.parse("$getCustomeMcqListApi$id?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to getMcqExamQuestionList');
    }
  }

  Future<List<test.TestData>> getReBookmarkMacqQuestionList(String type,
      String sectionType, String id, bool isAll, bool isCustom) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(sectionType);
    print(isCustom);
    print(isCustom
        ? "$getCustomPracticeQsList$id?type=$type&isAll=$isAll"
        : sectionType == "McqBookmark"
            ? "$getReBookmarkMCQQuestionListApi$id?type=$type&isAll=$isAll"
            : "$getReBookmarkMockQuestionListApi$id?type=$type&isAll=$isAll");
    final response = await http.get(
        Uri.parse(isCustom
            ? "$getCustomPracticeQsList$id?type=$type&isAll=$isAll"
            : sectionType == "McqBookmark"
                ? "$getReBookmarkMCQQuestionListApi$id?type=$type&isAll=$isAll"
                : "$getReBookmarkMockQuestionListApi$id?type=$type&isAll=$isAll"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to getMcqExamQuestionList');
    }
  }

  Future<McqExamData?> getCustomAnalysisBookmark(
      String type, String id, bool isAll) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    print(isAll);
    String? token = prefs.getString("token");
    String apiType = isAll
        ? type == "MockBookmark"
            ? "MockAllSolve"
            : "McqAllSolve"
        : type;
    String apiId = isAll ? "6719b2d0ddf6a41c091c0f90" : id;
    print("$getCustomAnalysisBookmarkApi/${apiId}?type=$apiType");
    final response = await http.get(
        Uri.parse("$getCustomAnalysisBookmarkApi/${apiId}?type=$apiType"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return McqExamData.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
    } else {
      throw Exception('Failed to getAllMyCustomTestBookmark');
    }
  }

  Future<bool?> getCustomDeleteBookmark(String type, String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("$deleteBookmarkTestApi/${id}?type=$type");
    final response = await http.delete(
        Uri.parse("$deleteBookmarkTestApi/${id}?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return true;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
    } else {
      throw Exception('Failed to getCustomDeleteBookmark');
    }
  }

  Future<Map<String, dynamic>> onCreateCustomeExamCreate(
      String type, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print("=========>${data}<=========");
    final response = await http.post(
        Uri.parse("$customUserExamCreateExam?type=$type"),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    log("response ${response.statusCode}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to getAllMyCustomTestBookmark');
    }
  }

  Future<void> createBookmarkExam(
      Map<String, dynamic> data, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log(data.toString());
    final response = await http.post(Uri.parse("$createTest?type=${type}"),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
    } else {
      throw Exception('Failed to createBookmarkExam');
    }
  }
  ////////////////

  Future<UserExamAnswer> getAnsByQuestion(
      String userExamId, String queId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log(token.toString());
    final response = await http.get(
        Uri.parse("$getQuesAnswer/$userExamId/$queId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response of get ansby question ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuizExamAnswer> getAnsByQuizQuestion(
      String userExamId, String queId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$getQuizQuesAnswer/$userExamId/$queId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response of get ansby question getQuizQuesAnswer ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<UserCustomExamAnswer> getAnsByCustomTestQuestion(
      String userExamId, String queId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$getCustomTestQuesAnswer/$userExamId/$queId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response of get ansby question getCustomTestQuesAnswer ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserCustomExamAnswer.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UserCustomExamAnswer.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<QuestionPalleteModel>> questionPallete(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$testQuestionPallete/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("questionPallete ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuestionPalleteModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuestionPalleteModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<QuizQuestionPalleteModel>> quizQuestionPalletes(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$quizQuestionPallete/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("questionPallete ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizQuestionPalleteModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizQuestionPalleteModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestQuestionPalleteModel>> customTestQuestionPallete(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$customTestQuestionPalletes/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("questionPallete $id ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestQuestionPalleteModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestQuestionPalleteModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<QuestionPalleteModel>> masterQuestionPallete(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$masterTestQuestionPallete/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("masterQuestionPallete ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuestionPalleteModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuestionPalleteModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SectionQuestionPalleteModel>> sectionQuestionPallete(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$sectionTestQuestionPallete/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("sectionQuestionPallete ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SectionQuestionPalleteModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SectionQuestionPalleteModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuestionPalleteCountModel> quesPalleteCount(String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$testQuestionPalleteCount/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuestionPalleteCountModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuestionPalleteCountModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuizQuestionPalleteCountModel> quesPalleteCountQuiz(
      String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$quizTestQuestionPalleteCount/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response quizTestQuestionPalleteCount${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizQuestionPalleteCountModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuizQuestionPalleteCountModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CustomTestQuestionPalleteCountModel> quesPalleteCountCustomTest(
      String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$customTestQuestionPalleteCount/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response quesPalleteCountCustomTest $userExamId ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestQuestionPalleteCountModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CustomTestQuestionPalleteCountModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<QuestionPalleteCountModel> quesMasterPalleteCount(
      String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$masterTestQuestionPalleteCount/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuestionPalleteCountModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return QuestionPalleteCountModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<SectionQuestionPalleteCountModel> quesSectionWisePalleteCount(
      String userExamId, String sectionId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$sectionTestQuestionPalleteCount/$userExamId/$sectionId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SectionQuestionPalleteCountModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return SectionQuestionPalleteCountModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<AllSectionQuestionPalleteCountModel>>
      quesAllSectionWisePalleteCount(String userExamId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = sectionAllQuestionPalleteCount;
    final response = await http.get(Uri.parse("$url/$userExamId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response quesAllSectionWisePalleteCount${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => AllSectionQuestionPalleteCountModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => AllSectionQuestionPalleteCountModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }
  // Future<List<SolutionReportsModel>> solutionReportByType(String id, String? type) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   String? token = prefs.getString("token");
  //   String url=solutionReportCategory;
  //   if(type=="category"){
  //     url=solutionReportCategory;
  //   }else if(type=="subcategory"){
  //     url=solutionReportSubCategory;
  //   }else if(type=="topic"){
  //     url=solutionReportTopic;
  //   }
  //   final response = await http.get(Uri.parse("$url/$id"),
  //       headers: {'Content-Type': 'application/json',
  //         'Authorization':token!});
  //
  //   log("response ${response.body}");
  //   if (response.statusCode == 200) {
  //     final List<dynamic> jsonData = jsonDecode(response.body);
  //     return jsonData.map((item) => SolutionReportsModel.fromJson(item)).toList();
  //   } else if(response.statusCode == 500){
  //     final List<dynamic> jsonData = jsonDecode(response.body);
  //     return jsonData.map((item) => SolutionReportsModel.fromJson(item)).toList();
  //   } else {
  //     throw Exception('Failed to fetch users');
  //   }
  // }

  Future<List<SolutionReportsModel>> solutionReportByExam(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = type != "" ? getCustomSolution2 : solutionReportCategory;
    final response = await http.get(Uri.parse("$url/$id?type=${type}"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("request ${"$url/$id?type=${type}"}");
    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<test.TestData>> getMcqExamQuestionList(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = getMcqQuestionList;
    final response = await http.get(Uri.parse("$url/$id?type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("request ${url + id + type}");
    log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => test.TestData.fromJson(item)).toList();
    } else {
      throw Exception('Failed to getMcqExamQuestionList');
    }
  }

  Future<List<QuizSolutionReportsModel>> solutionReportByQuizExam(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = quizSolutionReport;
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response solutionReportByQuizExam${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizSolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => QuizSolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<CustomTestSolutionReportsModel>> solutionReportByCustomTestExam(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = customTestSolutionReportCategory;
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response customTestSolutionReportCategory ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestSolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => CustomTestSolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<MasterSolutionReportsModel>> solutionReportByMasterExam(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = masterSolutionReportCategory;
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("request mock${url + id}");
    log("response master merit${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => MasterSolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => MasterSolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<MeritListModel>> meritListByExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$mertiListExam/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response mertilist ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => MeritListModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => MeritListModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<MeritListModel>> meritListByMasterExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$mertiListMasterExam/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    log("response meritMasterList ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => MeritListModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => MeritListModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ExamReport> compareWithRank1(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$compareWithRank/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    log(response.body.toString());
    log("response meritMasterList ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ExamReport.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkMainListModel>> bookmarkListAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getBookMarkList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkMainListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkMainListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<UpdateBookMarkModel> bookMarkQuestion(bool isBookMarked, String examId,
      String questionId, String? bookMarkNote) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(updateBookMark),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'bookmarks': isBookMarked,
          'exam_id': examId,
          'question_id': questionId,
          'Notes': bookMarkNote
        }));
    // log("response ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UpdateBookMarkModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UpdateBookMarkModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkByExamListModel>> bookMarkExamByCategoryList(
      String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = bookMarkCategory;
    if (type == "category") {
      url = bookMarkCategory;
    } else if (type == "subcategory") {
      url = bookMarkSubCategory;
    } else if (type == "topic") {
      url = bookMarkTopic;
    }
    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    log("response url:$url");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkByExamListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkByExamListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkByExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkByExamListModel>> masterBookMarkExamByList(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = masterBookMarkExamList;

    final response = await http.get(Uri.parse("$url/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response masterBookMarkExamByList${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkByExamListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkByExamListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkByExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkByExamListModel>> masterBookMarkExamByListv2(
      List<String> ids, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    String url = masterBookMarkExamListv2;

    final response = await http.get(
        Uri.parse("$url").replace(queryParameters: {
          'id': ids, // List<String> directly works with queryParameters in Dart
          'type': type,
        }),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response masterBookMarkExamByList${response.body}");
    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      if (jsonData is List) {
        return jsonData
            .map((item) => BookMarkByExamListModel.fromJson(item))
            .toList();
      } else if (jsonData is Map<String, dynamic>) {
        return [BookMarkByExamListModel.fromJson(jsonData)];
      } else {
        throw Exception('Invalid JSON response');
      }
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkByExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookMarkExamListModel>> bookMarkListByExam(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse("$getbookmarkAttempt/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkExamListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookMarkExamListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SolutionReportsModel>> bookMarkExamQuestionList(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$getbookmarksQuestions/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SolutionReportsModel>> masterBookMarkExamQuestionList(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$getmasterBookmarksQuestions/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SolutionReportsModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> deleteBookMarkQuestions(String bookmarkId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.delete(
        Uri.parse("$deletebookmarksQuestions/$bookmarkId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 201) {
      log('successfully deleted bookmark');
    } else if (response.statusCode == 500) {
      log('unsuccessful delete bookmark');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<FeaturedListModel> getFeaturedList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getFeaturedContents),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return FeaturedListModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return FeaturedListModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetBlogsListModel>> getBlogsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getBlogsLists),
        headers: {'Content-Type': 'application/json', 'Authorization': token ?? ''});

    log("response getBlogsList${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetBlogsListModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetBlogsListModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetBlogDetailsModel> getBlogsDetails(String blogId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$getBlogDetails/$blogId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token ?? ''});

    log("response getBlogsDetails${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetBlogDetailsModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetBlogDetailsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetTestimonialListModel>> getTestimonialList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getTestimonialLists),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetTestimonialListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetTestimonialListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateQuerySolutionReportModel> createQuery(
    String questionId,
    String query,
    bool incorrectQues,
    bool incorrectAns,
    bool explanationIssue,
    bool otherIssue,
    bool wrongImg,
    bool imgNotClear,
    bool spelingError,
    bool explainQueNotMatch,
    bool explainAnsNotMatch,
    bool queAnsOptionNotMatch,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createQuerySolutionReport),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'question_id': questionId,
          'query': query,
          'IncorrectQuestion': incorrectQues,
          'IncorrectAnswer': incorrectAns,
          'ExplanationIssue': explanationIssue,
          'OtherIssue': otherIssue,
          'WrongImg': wrongImg,
          'ImgNotClear': imgNotClear,
          'SpelingError': spelingError,
          'Expl_Qs_NotMatch': explainQueNotMatch,
          'Expl_An_NotMatch': explainAnsNotMatch,
          'Qs_An_Option_NotMatch': queAnsOptionNotMatch,
        }));

    log("response add query ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuerySolutionReportModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuerySolutionReportModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateQueryMockModel> createMockQuery(
      String questionId,
      String query,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createQueryMock),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'question_id': questionId,
          'query': query,
          'IncorrectQuestion': incorrectQues,
          'IncorrectAnswer': incorrectAns,
          'ExplanationIssue': explanationIssue,
          'OtherIssue': otherIssue,
        }));

    log("response add query ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQueryMockModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQueryMockModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateCustomTestQueryModel> createQueryCustomTest(
      String questionId,
      String query,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createCustomTestQuery),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'question_id': questionId,
          'query': query,
          'IncorrectQuestion': incorrectQues,
          'IncorrectAnswer': incorrectAns,
          'ExplanationIssue': explanationIssue,
          'OtherIssue': otherIssue,
        }));

    log("response add createQueryCustomTest ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateCustomTestQueryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateCustomTestQueryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<CreateQuizQueryModel> createQueryQuiz(
      String questionId,
      String query,
      bool incorrectQues,
      bool incorrectAns,
      bool explanationIssue,
      bool otherIssue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createQuizQuery),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'question_id': questionId,
          'query': query,
          'IncorrectQuestion': incorrectQues,
          'IncorrectAnswer': incorrectAns,
          'ExplanationIssue': explanationIssue,
          'OtherIssue': otherIssue,
        }));

    log("response add query ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuizQueryModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateQuizQueryModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch exams');
    }
  }

  Future<GetUserDetailsModel> showUserDetails(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getUserDetails),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response ${response.body}");
    if (response.statusCode == 200) {
      // Debug: print the full profile payload to verify presence of encryption key
      try { print('[PROFILE] payload=' + response.body); } catch (_) {}
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      // Persist encryption key if present in profile payload (supports multiple field names)
      try {
        String? keyFieldName;
        dynamic rawKey;
        if (jsonData.containsKey('videoEncryptKey')) { keyFieldName = 'videoEncryptKey'; rawKey = jsonData['videoEncryptKey']; }
        else if (jsonData.containsKey('encryption_key')) { keyFieldName = 'encryption_key'; rawKey = jsonData['encryption_key']; }
        else if (jsonData.containsKey('mediaKey')) { keyFieldName = 'mediaKey'; rawKey = jsonData['mediaKey']; }
        else if (jsonData.containsKey('video_key')) { keyFieldName = 'video_key'; rawKey = jsonData['video_key']; }
        if (rawKey is String && rawKey.isNotEmpty) {
          List<int>? keyBytes;
          String method = 'n/a';
          if (keyFieldName == 'encryption_key') {
            // Strict hex decode: 64 hex chars -> 32 bytes
            final s = rawKey.trim();
            final hexRe = RegExp(r'^[0-9a-fA-F]{64}$');
            if (hexRe.hasMatch(s)) {
              final out = <int>[];
              for (int i = 0; i < 64; i += 2) {
                out.add(int.parse(s.substring(i, i + 2), radix: 16));
              }
              if (out.length == 32) { keyBytes = out; method = 'hex'; }
            }
          } else {
            // Other fields expected as base64
            try {
              final b64 = base64Decode(rawKey);
              if (b64.length == 32) { keyBytes = b64; method = 'base64'; }
            } catch (_) {}
          }
          try { print('[PROFILE][KEY] field=' + (keyFieldName ?? 'unknown') + ' bytes=' + (keyBytes?.length.toString() ?? '0') + ' method=' + method); } catch (_) {}
          if (keyBytes != null && keyBytes.length == 32) {
            try { await SecureKeys.deleteKey('global'); } catch (_) {}
            await SecureKeys.saveKey('global', keyBytes);
            try {
              final re = await SecureKeys.loadKey('global');
              print('[PROFILE][KEY] saved_len=' + (re?.length.toString() ?? 'null'));
            } catch (_) {}
          }
        }
      } catch (_) {
        // Ignore key persistence errors; continue returning profile
      }
      return GetUserDetailsModel.fromJson(jsonData);
    } else if (response.statusCode == 401) {
      // Navigator.of(context).pushNamed(Routes.loginWithPass);
      Navigator.of(context).pushNamed(Routes.login);
      throw Exception('User Not Found');
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetUserDetailsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<ProgressDetailsModel> showProgressDetails(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getProgressDataDetails),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ProgressDetailsModel.fromJson(jsonData);
    } else if (response.statusCode == 401) {
      // Navigator.of(context).pushNamed(Routes.loginWithPass);
      Navigator.of(context).pushNamed(Routes.login);
      throw Exception('User Not Found');
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return ProgressDetailsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<UpdateUserProfileModel> updateUserProfile(
      String userId,
      String fullname,
      String dob,
      String preparingFor,
      String stateValue,
      List<String> preparingExams,
      String currentData,
      String phone,
      String email,
      {String? standerdId, String? preparingId}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    // Extract standerd_for as a string from the list
    final String standerdForString = preparingExams.isNotEmpty ? preparingExams[0] : '';
    
    final response = await http.put(Uri.parse("$updateUserDetails/$userId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'fullname': fullname,
          'date_of_birth': dob,
          'preparing_for': preparingFor,
          'standerd_for': standerdForString,
          'stateValue': stateValue,
          'current_data': currentData,
          'phone': phone,
          'email': email,
          if (standerdId != null && standerdId.isNotEmpty) 'standerd_id': standerdId,
          if (preparingId != null && preparingId.isNotEmpty) 'preparing_id': preparingId,
        }));

    debugPrint("request updateUserProfile ${response.body}");
    debugPrint("response updateUserProfile ${response.body}");
    // log("response ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UpdateUserProfileModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return UpdateUserProfileModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateTestimonialModel> createTestimonialReview(
      String name, String description, int rating) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createTestimonialUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'name': name,
          'description': description,
          'rating': rating,
        }));

    log("response testimonial ${response.body}");
    log("response testimonial name $name");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateTestimonialModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateTestimonialModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetOffersModel> getAllOffer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getOfferBanner),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response offerbanner ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetOffersModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetOffersModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetMockTestDetailsModel> getMockTestDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getMasterExamCount),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response offerbanner ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetMockTestDetailsModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetMockTestDetailsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<SubscribedPlanModel>> getSubscribedUserPlan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getSubscribedPlannew),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});
    print("request subscribed plan ${getSubscribedPlannew}");
    print("token $token");
    print("response subscribed plan ${response.body.toString()}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SubscribedPlanModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => SubscribedPlanModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetAllUserOrderModel>> getOrderHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getAllBookOrder),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllBookOrder ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllUserOrderModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllUserOrderModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetAllCouponUserModel>> getAllCouponUser(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$getAllCouponByUser/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response subscribed plan ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllCouponUserModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllCouponUserModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetAllOfferUserModel>> getAllOfferUser(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse("$getAllOfferByUser/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllOfferUser ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllOfferUserModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GetAllOfferUserModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<BookBySubscriptionIdModel>> getAllBookBySubscription(
      String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(
        Uri.parse("$getAllBookBySubscriptionPlan/$id"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllBookBySubscription ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookBySubscriptionIdModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => BookBySubscriptionIdModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetAllBookModel>> getAllHardCopyBook() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    // final response = await http.get(Uri.parse("$getAllBookList?preparing_for=INI-SSET"),
    final response = await http.get(Uri.parse(getAllBookList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    debugPrint("response getAllHardCopyBook ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetAllBookModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetAllBookModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateAddressModel> postAddress(
      String buildingNumber,
      String landMark,
      int pinCode,
      String city,
      String state,
      int phone,
      String name,
      String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "buildingNumber": buildingNumber,
      "LandMark": landMark,
      "Pincode": pinCode,
      "City": city,
      "State": state,
      "phone": phone,
      "name": name,
      "email": email,
    };
    final response = await http.post(Uri.parse(createAddress),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of postAddress ${response.body}");
    if (response.statusCode == 201) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateAddressModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateAddressModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<CreateAddressModel> updateUserAddress(
      String addressId,
      String buildingNumber,
      String landMark,
      int pinCode,
      String city,
      String state,
      int phone,
      String name,
      String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "buildingNumber": buildingNumber,
      "LandMark": landMark,
      "Pincode": pinCode,
      "City": city,
      "State": state,
      "phone": phone,
      "name": name,
      "email": email,
    };
    final response = await http.put(Uri.parse("$updateAddress/$addressId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));
    log("response of postAddress ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateAddressModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return CreateAddressModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<GetAddressModel>> getAllUserAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getAddresses),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getAllUserAddress ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetAddressModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => GetAddressModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<BookOfferModel> getBooksOffer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getBookOffer),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getBooksOffer ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return BookOfferModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return BookOfferModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<PaymentMethodDetailsModel> getPaymentDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    final response = await http.get(Uri.parse(getPaymentMethod),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response subscribed plan ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return PaymentMethodDetailsModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return PaymentMethodDetailsModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotificationListModel>> getNotificationList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(notificationList),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response notilist ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotificationListModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotificationListModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<PreparingForModel>> getPreparingExams() async {
    final response = await http.get(Uri.parse(getPreparingForExams),
        headers: {'Content-Type': 'application/json'});

    // log("response exams ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => PreparingForModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => PreparingForModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<StandardModel>> getStanderdList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(Uri.parse(getStanderdUrl),
        headers: {'Content-Type': 'application/json', if (token != null && token.isNotEmpty) 'Authorization': token});

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => StandardModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => StandardModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch standerd list');
    }
  }

  Future<List<StandardModel>> getStanderdByPreparing(String preparingId) async {
    final response = await http.get(
      Uri.parse("$getStanderdByPreparingId/$preparingId"),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => StandardModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => StandardModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch standards by preparing id');
    }
  }

  Future<List<VideoCategoryModel>> getSearchedData(String keyword) async {
    // log('keyword$keyword');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSearchByKeyword?searchname=$keyword"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response searchedData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => VideoCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<VideoSubCategoryModel>> getSearchedSubCategoryData(
      String keyword, String catId) async {
    // log('keyword$keyword');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSearchBySubCatKeyword/$catId?searchname=$keyword"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response searchedData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => VideoSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesCategoryModel>> getSearchedNotesData(String keyword) async {
    // log('keyword$keyword');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSearchByKeyword?searchname=$keyword"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response searchedData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => NotesCategoryModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => NotesCategoryModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<List<NotesSubCategoryModel>> getSearchedSubCategoryNotesData(
      String keyword, String catId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSearchBySubCatKeyword/$catId?searchname=$keyword"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response searchedData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesSubCategoryModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => NotesSubCategoryModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetSettingsDataModel> getSettingsData() async {
    final response = await http.get(Uri.parse(getSettings),
        headers: {'Content-Type': 'application/json'});

    log("response settings ${response.body}");
    debugPrint("response settings ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetSettingsDataModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetSettingsDataModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> onCreateNotes(String queId, String notes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.post(Uri.parse(createNote),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({
          'question_id': queId,
          'Notes': notes,
        }));

    log("response onCreateNotes${response.body}");
    if (response.statusCode == 201) {
      log('successfully notes added');
    } else if (response.statusCode == 500) {
      log('unsuccessful notes added');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<void> onCreateAnnotation(Map<String, dynamic> payload) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log(payload.toString());
    final response = await http.post(Uri.parse(createPdfAnnotationData),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(payload));
    if (response.statusCode == 200) {
      debugPrint('successfully notes annotation added');
    } else if (response.statusCode == 500) {
      debugPrint('unsuccessful notes added');
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  Future<GetNotesSolutionModel> getNotesData(String queId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log('quesId$queId');
    final response = await http.get(Uri.parse("$getNote/$queId"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    // log("response notes ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetNotesSolutionModel.fromJson(jsonData);
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      return GetNotesSolutionModel.fromJson(jsonData);
    } else {
      throw Exception('Failed to fetch notes');
    }
  }

  Future<List<SearchedDataModel>> getSearchedListData(
      String keyword, String type) async {
    log('keyword$keyword');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
        Uri.parse("$getSearch?searchname=$keyword&type=$type"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response searchedListData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => SearchedDataModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => SearchedDataModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch search data');
    }
  }

  Future<List<GlobalSearchDataModel>> getGlobalSearchedListData(
      String type, String selectedVal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    debugPrint("request$getGlobalSearch?searchname=$type&type=$selectedVal");
    final response = await http.get(
        Uri.parse("$getGlobalSearch?searchname=$type&type=$selectedVal"),
        headers: {'Content-Type': 'application/json', 'Authorization': token!});

    log("response getGlobalSearchedListData ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GlobalSearchDataModel.fromJson(item))
          .toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData
          .map((item) => GlobalSearchDataModel.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to fetch search data');
    }
  }

  Future<List<test.TestData>> getExamQuestionsList(
      String type, String id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response = await http
          .get(Uri.parse("$getExamQuestionList$id?type=$type"), headers: {
        'Content-Type': 'application/json',
        'Authorization': token!
      });

      log("response getExamQuestionList ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => test.TestData.fromJson(item)).toList();
      } else if (response.statusCode == 500) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => test.TestData.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch getExamQuestionList');
      }
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<bool> saveExamQuestionsList(
      List<ExamAnsModel> ans, String type) async {
    try {
      log(ans.map((e) => e.toJson()).toList().toString());
      log(type);
      if (type == "McqBookmark" || type == "MockBookmark" || type == "Custom") {
        log("$customUserAnswerCreateApi?type=$type");
      } else {
        log("$createUserAnswerByType?type=$type");
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response = await http.post(
          Uri.parse(type == "McqBookmark" ||
                  type == "MockBookmark" ||
                  type == "Custom"
              ? "$customUserAnswerCreateApi?type=$type"
              : "$createUserAnswerByType?type=$type"),
          body: jsonEncode(ans.map((e) => e.toJson()).toList()),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token!
          });
      log(response.statusCode.toString());
      log("response saveExamQuestionsList ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<bool> saveExplAnnotation(Map<String, dynamic> data) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      final response = await http.post(Uri.parse("$createExplAnnotation"),
          body: jsonEncode(data),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': token!
          });
      log(response.statusCode.toString());
      log("response saveExplAnnotation ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }
      return false;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  Future<List<PlanCategoryModel>> getAllPlanCategory() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      debugPrint("token$token");
    final response = await http.get(
      Uri.parse(getAllPlanCategoryGoal),
      headers: {'Content-Type': 'application/json',
      'Authorization': token!},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => PlanCategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch plan categories');
    }
  }

  Future<List<PlanSubcategoryModel>> getSubByCatId(String categoryId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
      Uri.parse('$getAllCustomSubsriptionByCatId/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token!
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((e) => PlanSubcategoryModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch subcategories');
    }
  }

  Future<List<BookModel>> getAllBooks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    debugPrint("token$token");
    final response = await http.get(
      Uri.parse(getAllBookUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );

    debugPrint("response getAllBooks ${response.body}");
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => BookModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => BookModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch books');
    }
  }

  Future<List<Map<String, dynamic>>> checkServiceability(
    String pincode, 
    double weight, {
    double? height,
    double? width,
    double? length,
    double? breadth,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    
    try {
      final queryParams = {
        'delivery_postcode': pincode,
        'weight': weight.toString(),
      };
      
      // Add dimensions if provided
      if (height != null) queryParams['height'] = height.toString();
      if (width != null) queryParams['width'] = width.toString();
      if (length != null) queryParams['length'] = length.toString();
      if (breadth != null) queryParams['breadth'] = breadth.toString();
      
      final uri = Uri.parse("$baseUrl/checkServiceability").replace(queryParameters: queryParams);
      debugPrint("request checkServiceability $uri");
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token!
        },
      );

      debugPrint("response checkServiceability ${response.body}");
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => item as Map<String, dynamic>).toList();
      } else {
        return [];
      }
    } catch (e) {
      debugPrint("Error checking serviceability: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createNewAddress(Map<String, dynamic> addressData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    
    try {
      final response = await http.post(
        Uri.parse(createAddress),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token!
        },
        body: jsonEncode(addressData),
      );

      log("response createAddress ${response.body}");
      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        return jsonData;
      } else {
        throw Exception('Failed to create address: ${response.statusCode}');
      }
    } catch (e) {
      log("Error creating address: $e");
      throw Exception('Error creating address: $e');
    }
  }

  // Verify coupon code
  Future<Map<String, dynamic>> verifyCouponCode(String couponCode) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }
      
      final url = Uri.parse('$baseUrl/getVerifyCoupon?code=$couponCode');
      final response = await http.get(
        url,
        headers: {'Authorization': token},
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        try {
          final couponResponse = CouponResponseModel.fromJson(responseData);
          return {
            'success': true,
            'message': couponResponse.message ?? 'Coupon applied successfully',
            'coupon': couponResponse.coupon?.toJson(),
          };
        } catch (e) {
          debugPrint('Error parsing coupon response: $e');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Coupon applied successfully',
            'coupon': responseData['coupon'],
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify coupon',
        };
      }
    } catch (e) {
      debugPrint('Error verifying coupon: $e');
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  Future<List<OfferModel>> getAllUserOffers() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String token = pref.getString('token') ?? '';
      
      final response = await http.get(
        Uri.parse(getAllUserOfferUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      
      log('Get All User Offers API Response: ${response.statusCode} ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((item) => OfferModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch user offers. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching user offers: $e');
      throw Exception('Error fetching user offers: $e');
    }
  }

  Future<void> purchaseMultipleSubscriptionPlans(List<Map<String, dynamic>> orderRequests) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String token = pref.getString('token') ?? '';
      debugPrint("orderRequest$orderRequests");
      final response = await http.post(
        Uri.parse(createMultiplePlans),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(orderRequests),
      );

      debugPrint('body resp${response.body}');
      if (response.statusCode != 201) {
        throw Exception('Failed to create subscription orders: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in purchaseMultipleSubscriptionPlans: $e');
      throw e;
    }
  }

  Future<void> purchaseBooks(List<Map<String, dynamic>> orderRequests) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String token = pref.getString('token') ?? '';
      
      // Ensure each order request has valid Address_id and courier_id
      for (var order in orderRequests) {
        if (order['Address_id'] == null) {
          debugPrint("Warning: Address_id is null in order request");
        }
        if (order['courier_id'] == null) {
          debugPrint("Warning: courier_id is null in order request");
        }
      }
      
      debugPrint("orderRequest$orderRequests");
      final response = await http.post(
        Uri.parse('$baseUrl/createBookOrderV2'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(orderRequests), 
      );
      debugPrint("response purchaseBooks ${response.body}");

      if (response.statusCode != 201) {
        throw Exception('Failed to create book orders: ${response.body}');
      }
      
      debugPrint('Book orders created successfully');
    } catch (e) {
      debugPrint('Error in purchaseBooks: $e');
      rethrow;
    }
  }

  // ... existing code ...
  Future<List<dynamic>> trackOrder(String orderId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    
    if (token == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trackOrder?order_id=$orderId'),
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      );
      debugPrint("request trackOrder $orderId");
      debugPrint("response trackOrder ${response.body}");
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData == null) {
          throw Exception('Empty response received from server');
        }
        
        return responseData as List<dynamic>;
      } else {
        throw Exception('Failed to track order: Status code ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in trackOrder API: $e');
      if (e is FormatException) {
        throw Exception('Invalid response format from tracking server');
      }
      throw Exception('Error tracking order: ${e.toString()}');
    }
  }

  Future<List<PincodeAddressModel>> getPincodeAddresses(String pincode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    final response = await http.get(
      Uri.parse('$baseUrl/getPinCodeAddress?pincode=$pincode'),
      headers: {'Authorization': token!},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((address) => PincodeAddressModel.fromJson(address)).toList();
    } else {
      throw Exception('Failed to fetch addresses for pincode: $pincode');
    }
  }
  
  Future<void> deleteHistory(String id, String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    log("request deleteHistory $deleteHistoryUrl/$id?type=$type");
    final response = await http.delete(
      Uri.parse("$deleteHistoryUrl/$id?type=$type"),
      headers: {'Content-Type': 'application/json', 'Authorization': token!},
    );
    log("response deleteHistory ${response.body}");
    log("response deleteHistory ${response.statusCode}");
    if (response.statusCode == 201) {
      log('successfully deleted history');
    } else if (response.statusCode == 500) {
      log('successfully deleted history');
    } else {
      throw Exception('Failed to delete history');
    }
  }

  Future<Map<String, dynamic>> verifyUpdateUser(
      String info, String type, String otp) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    print(info);
    print(type);
    print(otp);
    final response = await http.post(
      Uri.parse(verifyUpdateNumberUser),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token ?? '',
      },
      body: jsonEncode(type == 'email'
          ? {
              'email': info,
              'userOTP': otp,
            }
          : {
              'phone': info,
              'userOTP': otp,
            }),
    );
    print(response.statusCode);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      jsonData['status'] = true;
      return jsonData;
    } else if (response.statusCode == 400) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      jsonData['status'] = false;
      return jsonData;
    } else if (response.statusCode == 500) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      jsonData['status'] = false;
      return jsonData;
    } else {
      throw Exception('Failed to verify user update');
    }
  }

  Future<void> noteProgressTime(String contentId, int? pageNo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    Map<String, dynamic> params = {
      "content_id": contentId,
      if (pageNo != null && pageNo != 0) "pageNumber": pageNo,
    };
    debugPrint("params$params");
    final response = await http.post(Uri.parse(videoContentProgress),
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(params));

    debugPrint("response noteProgressTime ${response.body}");
    if (response.statusCode == 201) {
      debugPrint('successfully saved note progress');
    } else if (response.statusCode == 500) {
      debugPrint('unsuccessful save note progress');
    } else {
      throw Exception('Failed to save note progress');
    }
  }

  /// Fetches the list of upgrade plans for a user
  Future<List<AllPlansResponseModel>> getUpgradePlanList({
    required String subscriptionId,
    bool? sameValidity, // Now nullable
    bool? isDiffValidity, // Now nullable
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    // Build query string dynamically
    String query = '';
    if (sameValidity != null && sameValidity) {
      query = 'sameValidity=true';
    } else if (isDiffValidity != null && isDiffValidity) {
      query = 'isDiffValidity=true';
    }
    final url = query.isNotEmpty
        ? '$baseUrl/getUpgradePlanList/$subscriptionId?$query'
        : '$baseUrl/getUpgradePlanList/$subscriptionId';
    debugPrint("url$url");
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token!,
      },
    );
    log("response getUpgradePlanList $url: \\${response.body}");
    if (response.statusCode == 200) {
      // Parse as a list, just like subscription_plan_store.dart
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => AllPlansResponseModel.fromJson(item)).toList();
    } else if (response.statusCode == 500) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((item) => AllPlansResponseModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch upgrade plans');
    }
  }

  /// Deletes multiple history types for the user by calling the backend API.
  /// [types] is a list of history type strings (e.g., ['video', 'mcq']).
  /// Throws an exception if the API call fails.
  Future<void> deleteAllHistory(List<String> types) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");
    if (token == null) throw Exception('User not authenticated');
    // Build query string: type=video&type=pdf etc.
    final query = types.map((t) => 'type=$t').join('&');
    final url = Uri.parse('$baseUrl/deleteAllHistory?$query');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
    );
    debugPrint("response deleteAllHistory ${response.body}");
    if (response.statusCode != 200) {
      throw Exception('Failed to delete history: \\${response.body}');
    }
  }

  Future<void> createAppleInAppPurchaseOrder({
    required String planId,
    required int amount,
    required int day,
    String? durationId,
  }) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String token = pref.getString('token') ?? '';

      final payload = {
        "plan_id": planId,
        "amount": amount,
        "day": day,
        if (durationId != null) "duration_id": durationId,
      };

      final response = await http.post(
        Uri.parse(createInAPurchasesOrder),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(payload),
      );

      debugPrint('createAppleInAppPurchaseOrder resp ${response.statusCode}: ${response.body}');
      if (!(response.statusCode == 201 || response.statusCode == 200)) {
        throw Exception('Failed to create Apple IAP subscription order: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in createAppleInAppPurchaseOrder: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER FEATURES  (bookmarks / resume / streak / review / prefs / device FCM)
  // All endpoints require the logged-in user bearer token.
  // Response shape is the platform-standard { success, data } envelope, so we
  // return the raw decoded `data` object and let callers parse as needed.
  // ═══════════════════════════════════════════════════════════════════════════

  Future<String?> _authToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// POST /api/user/video-bookmarks
  /// Returns the created bookmark document.
  Future<Map<String, dynamic>?> createVideoBookmark({
    required String contentId,
    required num positionSeconds,
    String? label,
    String? color,
  }) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final resp = await http.post(
        Uri.parse(userVideoBookmarks),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'content_id': contentId,
          'position_seconds': positionSeconds,
          if (label != null) 'label': label,
          if (color != null) 'color': color,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      debugPrint('createVideoBookmark ${resp.statusCode}: ${resp.body}');
      return null;
    } catch (e) {
      debugPrint('createVideoBookmark error: $e');
      return null;
    }
  }

  /// GET /api/user/video-bookmarks?content_id=...
  Future<List<Map<String, dynamic>>> listVideoBookmarks({String? contentId}) async {
    try {
      final token = await _authToken();
      if (token == null) return <Map<String, dynamic>>[];
      final qp = contentId != null && contentId.isNotEmpty
          ? '?content_id=$contentId'
          : '';
      final resp = await http.get(
        Uri.parse('$userVideoBookmarks$qp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = (decoded is Map) ? decoded['data'] : null;
        if (list is List) {
          return list
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('listVideoBookmarks error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// DELETE /api/user/video-bookmarks/:id
  Future<bool> deleteVideoBookmark(String bookmarkId) async {
    try {
      final token = await _authToken();
      if (token == null) return false;
      final resp = await http.delete(
        Uri.parse('$userVideoBookmarks/$bookmarkId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('deleteVideoBookmark error: $e');
      return false;
    }
  }

  /// GET /api/user/resume-list?limit=6
  /// Returns items with { content_id, title, thumbnail, time, pageNumber, last_watched_at }.
  Future<List<Map<String, dynamic>>> getResumeList({int limit = 6}) async {
    try {
      final token = await _authToken();
      if (token == null) return <Map<String, dynamic>>[];
      final resp = await http.get(
        Uri.parse('$userResumeList?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = (decoded is Map) ? decoded['data'] : null;
        if (list is List) {
          return list
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('getResumeList error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// GET /api/user/streak?tz=Asia/Kolkata
  /// Returns { current_streak, longest_streak, active_days_last_60, weekly: [...] }.
  Future<Map<String, dynamic>?> getUserStreak({String? timezone}) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final qp = timezone != null && timezone.isNotEmpty ? '?tz=$timezone' : '';
      final resp = await http.get(
        Uri.parse('$userStreak$qp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('getUserStreak error: $e');
      return null;
    }
  }

  /// GET /api/user/analytics/summary?tz=...
  Future<Map<String, dynamic>?> getUserAnalyticsSummary({String? timezone}) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final qp = timezone != null && timezone.isNotEmpty ? '?tz=$timezone' : '';
      final resp = await http.get(
        Uri.parse('$userAnalyticsSummary$qp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('getUserAnalyticsSummary error: $e');
      return null;
    }
  }

  /// GET /api/user/review/next?limit=20
  Future<List<Map<String, dynamic>>> getReviewNext({int limit = 20}) async {
    try {
      final token = await _authToken();
      if (token == null) return <Map<String, dynamic>>[];
      final resp = await http.get(
        Uri.parse('$userReviewNext?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = (decoded is Map) ? decoded['data'] : null;
        if (list is List) {
          return list
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('getReviewNext error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// POST /api/user/review/answer   rating: 'again' | 'hard' | 'good' | 'easy'
  Future<Map<String, dynamic>?> submitReviewAnswer({
    required String itemId,
    required String rating,
    int timeSpentMs = 0,
  }) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final resp = await http.post(
        Uri.parse(userReviewAnswer),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'item_id': itemId,
          'rating': rating,
          'time_spent_ms': timeSpentMs,
        }),
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('submitReviewAnswer error: $e');
      return null;
    }
  }

  /// POST /api/user/review/enqueue
  Future<Map<String, dynamic>?> enqueueForReview({
    required String questionId,
    String questionSource = 'Question',
    String reason = 'flagged',
  }) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final resp = await http.post(
        Uri.parse(userReviewEnqueue),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'question_id': questionId,
          'question_source': questionSource,
          'reason': reason,
        }),
      );
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('enqueueForReview error: $e');
      return null;
    }
  }

  /// GET /api/user/topic-mastery
  Future<List<Map<String, dynamic>>> getTopicMastery() async {
    try {
      final token = await _authToken();
      if (token == null) return <Map<String, dynamic>>[];
      final resp = await http.get(
        Uri.parse(userTopicMastery),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        final list = (decoded is Map) ? decoded['data'] : null;
        if (list is List) {
          return list
              .whereType<Map>()
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('getTopicMastery error: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// POST /api/user/device/register
  /// Upserts the FCM token for this (user, device) pair.
  Future<bool> registerUserDeviceFcm({
    required String fcmToken,
    String? appVersion,
  }) async {
    try {
      final token = await _authToken();
      if (token == null) return false;
      final info = await getDeviceInfo();
      final deviceId = info['device_id'] ?? '';
      final platform = (info['platform'] ?? '').toLowerCase();
      if (deviceId.isEmpty || fcmToken.isEmpty) return false;
      final resp = await http.post(
        Uri.parse(userDeviceRegister),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode({
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'platform': platform.isEmpty ? 'android' : platform,
          if (appVersion != null) 'app_version': appVersion,
        }),
      );
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('registerUserDeviceFcm error: $e');
      return false;
    }
  }

  /// DELETE /api/user/device/:deviceId
  Future<bool> unregisterUserDeviceFcm({String? deviceId}) async {
    try {
      final token = await _authToken();
      if (token == null) return false;
      String id = deviceId ?? '';
      if (id.isEmpty) {
        final info = await getDeviceInfo();
        id = info['device_id'] ?? '';
      }
      if (id.isEmpty) return false;
      final resp = await http.delete(
        Uri.parse('$userDeviceUnregister/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint('unregisterUserDeviceFcm error: $e');
      return false;
    }
  }

  /// GET /api/user/preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final resp = await http.get(
        Uri.parse(userPreferences),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('getUserPreferences error: $e');
      return null;
    }
  }

  /// PUT /api/user/preferences  — pass only the fields you want to change.
  Future<Map<String, dynamic>?> updateUserPreferences(Map<String, dynamic> patch) async {
    try {
      final token = await _authToken();
      if (token == null) return null;
      final resp = await http.put(
        Uri.parse(userPreferences),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token,
        },
        body: jsonEncode(patch),
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        return (decoded is Map && decoded['data'] is Map)
            ? Map<String, dynamic>.from(decoded['data'])
            : null;
      }
      return null;
    } catch (e) {
      debugPrint('updateUserPreferences error: $e');
      return null;
    }
  }
}
