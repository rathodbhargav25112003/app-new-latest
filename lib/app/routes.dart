import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shusruta_lms/modules/bookmarks/bookmark_category_list.dart';
import 'package:shusruta_lms/modules/bookmarks/bookmark_main_list.dart';
import 'package:shusruta_lms/modules/bookmarks/bookmark_question_detail.dart';
import 'package:shusruta_lms/modules/bookmarks/bookmark_question_list.dart';
import 'package:shusruta_lms/modules/cortex/cortex_chat_screen.dart';
// Cortex AI v2/v3 — multi-turn chat, modes, memory, snippets
import 'package:shusruta_lms/modules/cortex/cortex_home_screen.dart';
import 'package:shusruta_lms/modules/cortex/cortex_memory_screen.dart';
import 'package:shusruta_lms/modules/cortex/cortex_mode_start_screen.dart';
import 'package:shusruta_lms/modules/cortex/cortex_snippets_screen.dart';
import 'package:shusruta_lms/modules/hardcopy/chapter_details_screen.dart';
import 'package:shusruta_lms/modules/hardcopy/module_index_screen.dart';
import 'package:shusruta_lms/modules/hardcopy/purchase_hardcopy_screen.dart';
import 'package:shusruta_lms/modules/masterTest/choose_test_screen.dart';
import 'package:shusruta_lms/modules/masterTest/test_master_exam_screen.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/screens/performance_trends_screen.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/screens/reading_settings_screen.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/screens/scheduled_sessions_screen.dart';
import 'package:shusruta_lms/modules/mcq_review_v3/screens/study_plan_screen.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/new_custom_subscription_plan.dart';
import 'package:shusruta_lms/modules/notes/notes_subject_detail.dart';
import 'package:shusruta_lms/modules/reports/spr%20reports/spr_report_detail.dart';
import 'package:shusruta_lms/modules/reports/spr%20reports/spr_reports_list.dart';
import 'package:shusruta_lms/modules/splash/main_splash_screen.dart';
import 'package:shusruta_lms/modules/subscriptionplans/subscription_screen.dart';
import 'package:shusruta_lms/modules/test/show_test_screen.dart';
import 'package:shusruta_lms/modules/videolectures/video_subject_detail.dart';

import '../modules/bookmarks/bookmark_exam_attempt_list.dart';
import '../modules/bookmarks/bookmark_subcategory_screen.dart';
import '../modules/bookmarks/bookmark_topic_list.dart';
import '../modules/bookmarks/masterBookmarks/master_bookmark_category_list.dart';
import '../modules/bookmarks/masterBookmarks/master_bookmark_question_detail.dart';
import '../modules/bookmarks/masterBookmarks/select_master_bookmark_by_exam.dart';
import '../modules/bookmarks/select_bookmark_by_exam.dart';
import '../modules/customtests/custom_configuration.dart';
import '../modules/customtests/custom_preview.dart';
import '../modules/customtests/custom_test_exam_screen.dart';
import '../modules/customtests/custom_test_lists.dart';
import '../modules/customtests/custom_test_report_details_screen.dart';
import '../modules/customtests/custom_test_report_screen.dart';
import '../modules/customtests/custom_test_report_sub_category.dart';
import '../modules/customtests/custom_test_select_test.dart';
import '../modules/customtests/custom_test_solution_report.dart';
import '../modules/customtests/practice_custom_test_exam_screen.dart';
import '../modules/customtests/select_custom_test_category.dart';
import '../modules/customtests/select_custom_test_chapter.dart';
import '../modules/customtests/select_custom_test_topic.dart';
import '../modules/dashboard/about_screen.dart';
import '../modules/dashboard/continue_watching_screen.dart';
import '../modules/dashboard/dashboard_screen.dart';
import '../modules/dashboard/featured_notes_view.dart';
import '../modules/dashboard/featured_test_exam_screen.dart';
import '../modules/dashboard/featured_video_view.dart';
import '../modules/dashboard/notifications_screen.dart';
import '../modules/dashboard/search_screen.dart';
import '../modules/hardcopy/hardcopy_details_screen.dart';
import '../modules/hardcopyNotes/address_details.dart';
import '../modules/hardcopyNotes/address_details_with_subscription.dart';
import '../modules/hardcopyNotes/book_list_screen.dart';
import '../modules/hardcopyNotes/hardcopy_subscription_detail_screen.dart';
import '../modules/hardcopyNotes/select_subscription_with_hardcopy.dart';
import '../modules/hardcopyNotes/selected_subscription_plan_with_hard_copy_notes.dart';
import '../modules/hardcopyNotes/view_hard_copy_note_details.dart';
import '../modules/history/delete_history_screen.dart';
import '../modules/liveclass/live_class_main_screen.dart';
import '../modules/liveclass/live_classes.dart';
import '../modules/liveclass/live_classes_completed.dart';
import '../modules/liveclass/live_classes_upcoming.dart';
import '../modules/login/forgot_email.dart';
import '../modules/login/forgot_password.dart';
import '../modules/login/login_screen.dart';
import '../modules/login/login_with_phone_screen.dart';
import '../modules/login/store/verify_otp_phone.dart';
import '../modules/login/verify_otp_mail.dart';
import '../modules/masterTest/allTest_category.dart';
import '../modules/masterTest/all_select_test_list.dart';
import '../modules/masterTest/master_test_notification.dart';
import '../modules/masterTest/master_test_report_details_screen.dart';
import '../modules/masterTest/master_test_report_screen.dart';
import '../modules/masterTest/practice__master_test_exam_screen.dart';
import '../modules/masterTest/practice_custom_test_solution_screen.dart';
import '../modules/masterTest/practice_mock_solution_exam_screen.dart';
import '../modules/masterTest/sectionwisemasterTest/section_question_pallet.dart';
import '../modules/masterTest/sectionwisemasterTest/start_section_instruction_screen.dart';
import '../modules/new_subscription_plans/new_add_address.dart';
import '../modules/new_subscription_plans/new_checkout_plan.dart';
import '../modules/new_subscription_plans/new_select_offers_plan.dart';
import '../modules/new_subscription_plans/new_subscription.dart';
import '../modules/new_subscription_plans/ordered_book_list.dart';
import '../modules/new_subscription_plans/payment_success_screen.dart';
import '../modules/new_subscription_plans/select_delivery_type.dart';
import '../modules/new_subscription_plans/select_subscription_plan.dart';
import '../modules/new_subscription_plans/store/ordered_book_store.dart';
import '../modules/notes/downloaded_notes.dart';
import '../modules/notes/notes_category.dart';
import '../modules/notes/notes_chapter_detail.dart';
import '../modules/notes/notes_read_view.dart';
import '../modules/notes/notes_topic_category.dart';
import '../modules/notes/offline_category_list.dart';
import '../modules/notes/offline_subcategory_list.dart';
import '../modules/notes/offline_title_list.dart';
import '../modules/notes/offline_topic_list.dart';
import '../modules/orders/track_order_screen.dart';
import '../modules/progress/progress_screen.dart';
import '../modules/quiztest/quiz_exam_screen.dart';
import '../modules/quiztest/quiz_screen.dart';
import '../modules/quiztest/quiz_solution_report.dart';
import '../modules/quiztest/quiz_solution_screen.dart';
import '../modules/reports/master reports/master_report.dart';
import '../modules/reports/master reports/master_report_category_list.dart';
import '../modules/reports/master reports/master_report_main.dart';
import '../modules/reports/master reports/select_exam_master_report_list.dart';
import '../modules/reports/master reports/solution_master_report.dart';
import '../modules/reports/master reports/solution_test_notification.dart';
import '../modules/reports/report_category_list.dart';
import '../modules/reports/report_list.dart';
import '../modules/reports/report_main_screen.dart';
import '../modules/reports/report_sub_category.dart';
import '../modules/reports/reports_subcategory_list.dart';
import '../modules/reports/reports_topic_list.dart';
import '../modules/reports/select_exam_report_list.dart';
import '../modules/reports/solution_report.dart';
import '../modules/review/review_queue_screen.dart';
import '../modules/signup/edit_profile.dart';
import '../modules/signup/google_signup_form.dart';
import '../modules/signup/preparing_for_screen.dart';
import '../modules/signup/signup_screen.dart';
import '../modules/signup/signup_with_phone_screen.dart';
import '../modules/splash/splash_screen.dart';
import '../modules/subscriptionplans/address_details.dart';
import '../modules/subscriptionplans/payment_failed_screen.dart';
import '../modules/subscriptionplans/payment_successful_screen.dart';
import '../modules/subscriptionplans/select_book_and_subscription_screen.dart';
import '../modules/subscriptionplans/subscription_detail_screen.dart';
import '../modules/subscriptionplans/subscription_list.dart';
import '../modules/subscriptionplans/view_note_details.dart';
import '../modules/test/practice_test_exam_screen.dart';
import '../modules/test/practice_test_solution_exam_screen.dart';
import '../modules/test/select_test_list.dart';
import '../modules/test/test_category.dart';
import '../modules/test/test_chapter_detail.dart';
import '../modules/test/test_exam_screen.dart';
import '../modules/test/test_notification.dart';
import '../modules/test/test_report_details_screen.dart';
import '../modules/test/test_report_screen.dart';
import '../modules/test/test_subject_detail.dart';
import '../modules/testimonial_and_blog/blog_details_screen.dart';
import '../modules/testimonial_and_blog/blog_screen.dart';
import '../modules/testimonial_and_blog/testimonial_screen.dart';
import '../modules/upgrade_plans/select_upgrade_plan.dart';
import '../modules/verifyotp/verify_change_mobile_otp.dart';
import '../modules/verifyotp/verify_otp.dart';
import '../modules/videolectures/video_category.dart';
import '../modules/videolectures/video_chapter_detail.dart';
import '../modules/videolectures/video_player_detail.dart';
import '../modules/videolectures/video_topic_category.dart';

class Routes {
  static const String mainSplash = "mainsplash";
  static const String splash = "splash";
  static const String login = "login";
  static const String loginWithPass = "loginwithpass";
  static const String register = "registration";
  static const String registerWithPass = "registrationwithpass";
  static const String subscriptionPlan = "subscriptionplan";
  static const String subscriptionList = "subscriptionlist";
  static const String newSubscription = "newsubscription";
  static const String newCustomSubscription = "newcustomizesubscription";
  static const String newSelectSubscriptionPlan = "newselectsubscriptionplan";
  static const String newCheckoutPlan = "newcheckoutplan";
  static const String newSelectOffersPlan = "newselectoffersPlan";
  static const String newAddAddress = "newaddaddress";
  static const String selectDeliveryType = "selectdeliverytype";
  static const String subscriptionDetailPlan = "subscriptiondetail";
  static const String hardCopySubscriptionDetailPlan = "hardcopysubscriptiondetail";
  static const String selectedSubscriptionPlanScreen = "selectedsubscriptionplanscreen";
  static const String selectBookAndSubscriptionDetail = "selectbookandsubscriptiondetail";
  static const String verifyOtp = "verifyotp";
  static const String verifyOtpMail = "verifyotpmail";
  static const String verifyOtpPhone = "verifyotpphone";
  static const String forgotPassword = "forgotpassword";
  static const String dashboard = "dashboard";
  static const String home = "home";
  static const String googleSignUpForm = "googlesignupform";
  static const String videoLectures = "videolectures";
  static const String videoSubjectDetail = "videosubjectdetail";
  static const String VideoTopicCategory = "Videotopiccategory";
  static const String videoChapterDetail = "videochapterdetail";
  static const String videoPlayDetail = "videoplaydetail";
  static const String videoPlayDetailDemo = "videoplaydetaildemo";
  static const String notesCategory = "notescategory";
  static const String notesTopicCategory = "notestopiccategory";
  static const String notesSubjectDetail = "notessubjectdetail";
  static const String notesChapterDetail = "noteschapterdetail";
  static const String testCategory = "testcategory";
  static const String allTestCategory = "alltestcategory";
  static const String testSubjectDetail = "testsubjectdetail";
  static const String testChapterDetail = "testchapterdetail";
  static const String testReportScreen = "testreportscreen";
  static const String customTestReportScreen = "customtestreportscreen";
  static const String testReportDetailsScreen = "testreportdetailsscreen";
  static const String customTestReportDetailsScreen = "customtestreportdetailsscreen";
  static const String masterTestReportDetailsScreen = "mastertestreportdetailsscreen";
  static const String masterTestReportScreen = "mastertestreportscreen";
  static const String selectTestList = "selecttestlist";
  static const String allSelectTestList = "allselecttestlist";
  static const String chooseTestScreen = "chooseTestScreen";
  static const String startSectionInstructionScreen = "startsectioninstructionscreen";
  static const String testExams = "testExams";
  static const String customTestExams = "customTestExams";
  static const String testMasterExams = "testMasterExams";
  static const String sectionExams = "sectionExams";
  static const String quizTestExamScreen = "quizTestExamScreen";
  static const String featuredTestExamPage = "featuredTestExams";
  static const String practiceCustomTestExamScreen = "PracticeCustomTestExamScreen";
  static const String practiceTestExams = "practicetestExams";
  static const String practiceSolutionTestExams = "practiceSolutionTestExams";
  static const String mockPracticeSolutionTestExams = "mockPracticeSolutionTestExams";
  static const String practiceSolutionCustomTestExams = "practiceSolutionCustomTestExams";
  static const String practiceMasterTestExams = "practicemastertestExams";
  static const String questionPallet = "questionpallet";
  static const String sectionquestionPallet = "sectionquestionpallet";
  static const String notesReadView = "notesreadview";
  static const String reportList = "reportlist";
  static const String selectExamReportList = "selectexamreportlist";
  static const String selectMasterExamReportList = "selectmasterexamreportlist";
  static const String reportSubCategory = "reportsubcategory";
  static const String customTestReportSubCategory = "customtestreportsubcategory";
  static const String masterReport = "masterreport";
  static const String bookMarkList = "bookmarklist";
  static const String bookMarkExamList = "bookmarkexamlist";
  static const String masterBookMarkExamList = "mastrerbookmarkexamlist";
  static const String bookMarkExamAttemptList = "bookmarkexamattemptlist";
  static const String bookMarkQuestionList = "bookmarkquestionlist";
  static const String bookMarkQuestionDetail = "bookmarkquestiondetail";
  static const String masterBookMarkQuestionDetail = "masterbookmarkquestiondetail";
  static const String solutionReport = "solutionreport";
  static const String customTestSolutionReport = "customtestsolutionreport";
  static const String solutionMasterReport = "solutionmasterreport";
  static const String sprReportList = "sprreportlist";
  static const String sprReportDetail = "sprreportdetail";
  static const String reportMainScreen = "reportmainscreen";
  static const String masterReportMainScreen = "masterreportmainscreen";
  static const String editProfile = "editprofile";
  static const String verifyChangeMobileOtp = "verifychangemobileotp";
  static const String downloadedNotes = "downloadednotes";
  static const String downloadedNotesCategory = "downloadednotescategory";
  static const String downloadedNotesSubCategory = "downloadednotessubcategory";
  static const String downloadedNotesTopic = "downloadednotestopic";
  static const String downloadedNotesTitle = "downloadednotestitle";
  static const String downloadedVideoCategory = "downloadedvideocategory";
  static const String featuredNotes = "featurednotes";
  static const String featuredVideos = "featuredvideo";
  static const String paymentStatus = "paymentstatus";
  static const String paymentFailed = "paymentfailed";
  static const String notificationScreen = "notificationscreen";
  static const String testNotificationScreen = "testnotificationscreen";
  static const String solutionTestNotificationScreen = "solutionTestnotificationscreen";
  static const String masterTestNotificationScreen = "mastertestnotificationscreen";
  static const String customTestSelectCategory = "customtestselectcategory";
  static const String customTestSelectChapter = "customtestselectchapter";
  static const String customTestSelectTopic = "customtestselecttopic";
  static const String customTestSelectTest = "customtestselecttest";
  static const String blogScreen = "blogscreen";
  static const String blogDetailsScreen = "blogdetailsscreen";
  static const String testimonialScreen = "testimonialscreen";
  static const String quizScreen = "quizscreen";
  static const String showTestScreen = "ShowTestScreen";
  static const String quizSolutionScreen = "quizsolutionscreen";
  static const String quizSolutionReportScreen = "quizsolutionreportscreen";
  static const String customConfiguration = "customconfiguration";
  static const String customPreview = "custompreview";
  static const String customTestList = "customtestlist";
  static const String forgotEmailId = "forgotemail";
  static const String bookMarkCategoryList = "bookmarkcategorylist";
  static const String masterBookMarkCategoryList = "masterbookmarkcategorylist";
  static const String bookMarkSubcategoryList = "bookmarksubcategorylist";
  static const String bookMarkTopicList = "bookmarktopiclist";
  static const String reportsCategoryList = "reportscategorylist";
  static const String masterReportsCategoryList = "masterreportscategorylist";
  static const String reportsSubCategoryList = "reportssubcategorylist";
  static const String reportsTopicList = "reportstopiclist";
  static const String aboutus = "aboutuspage";
  static const String liveClassMainScreen = "liveclassmainscreen";
  static const String liveClasses = "liveclasses";
  static const String liveClassesUpcoming = "liveClassesupcoming";
  static const String liveClassesCompleted = "liveClassescompleted";
  static const String addressDetailScreen = "addressdetailscreen";
  static const String viewNoteDetails = "viewnotedetails";
  static const String viewHardCopyNoteDetails = "viewhardcopynotedetails";
  static const String bookListScreen = "booklistscreen";
  static const String hardCopyAddressScreen = "hardcopyaddressscreen";
  static const String hardCopyAndSubscriptionAddressScreen = "hardcopyandsubscriptionaddressscreen";
  static const String hardCopySubscriptionListScreen = "hardcopysubscriptionlistscreen";
  static const String searchScreen = "searchScreen";
  static const String continueWatchingScreen = "continueWatchingScreen";
  static const String progressScreen = "progressScreen";
  static const String newPaymentSuccess = "newpaymentsuccess";
  static const String trackOrder = "trackorder";
  static const String purchaseHardcopy = "purchasehardcopy";
  static const String hardcopyDetails = "hardcopydetails";
  static const String volumeIndex = "volumeindex";
  static const String chapterDetails = "/chapter-details";
  static const String paymentSuccessScreen = "paymentsuccessscreen";
  static const String trackOrderScreen = "trackorderscreen";
  static const String hardcopyDetailsScreen = "hardcopydetailsscreen";
  static const String orderedBookListScreen = "orderedbooklistscreen";
  static const String selectUpgradePlan = 'selectUpgradePlan'; // Upgrade plan selection screen route
  static const String deleteHistoryScreen = "deleteHistoryScreen";
  static const String preparingForScreen = "preparingForScreen";
  static const String reviewQueue = "reviewQueue";

  // Cortex AI v2/v3 routes
  static const String cortexHome = "cortexHome";
  static const String cortexChat = "cortexChat";
  static const String cortexModeStart = "cortexModeStart";
  static const String cortexMemory = "cortexMemory";
  static const String cortexSnippets = "cortexSnippets";

  // MCQ Review v3 routes
  static const String reviewQueueV3 = "reviewQueueV3";
  static const String studyPlan = "studyPlan";
  static const String scheduledSessions = "scheduledSessions";
  static const String performanceTrends = "performanceTrends";
  static const String readingSettings = "readingSettings";

  static String currentRoute = mainSplash;

  static Route<dynamic> onGenerateRouted(RouteSettings routeSettings) {
    currentRoute = routeSettings.name ?? "";
    switch (routeSettings.name) {
      case mainSplash:
        {
          return MainSplashScreen.route(routeSettings);
        }
      case splash:
        {
          return SplashScreen.route(routeSettings);
        }
      case login:
        {
          return LoginWithPhoneScreen.route(routeSettings);
        }
      case loginWithPass:
        {
          return LoginScreen.route(routeSettings);
        }
      case forgotEmailId:
        {
          return ForgotEmailScreen.route(routeSettings);
        }
      case forgotPassword:
        {
          return ForgotPasswordScreen.route(routeSettings);
        }
      case register:
        {
          return SignUpWithPhoneScreen.route(routeSettings);
        }
      case registerWithPass:
        {
          return SignUpScreen.route(routeSettings);
        }
      case subscriptionPlan:
        {
          return SubscriptionScreen.route(routeSettings);
        }
      case subscriptionList:
        {
          return SubscriptionList.route(routeSettings);
        }
      case newSubscription:
        {
          return NewSubscription.route(routeSettings);
        }
      case newCustomSubscription:
        {
          return NewCustomSubscriptionPlan.route(routeSettings);
        }
      case newSelectSubscriptionPlan:
        {
          return SelectSubscriptionPlan.route(routeSettings);
        }
      case newCheckoutPlan:
        {
          return NewCheckoutPlan.route(routeSettings);
        }
      case newSelectOffersPlan:
        {
          return NewSelectOffersPlan.route(routeSettings);
        }
      case newAddAddress:
        {
          return NewAddAddress.route(routeSettings);
        }
      case selectDeliveryType:
        {
          return SelectDeliveryType.route(routeSettings);
        }
      case verifyOtp:
        {
          return VerificationOtp.route(routeSettings);
        }
      case verifyOtpMail:
        {
          return VerificationOtpMail.route(routeSettings);
        }
      case verifyOtpPhone:
        {
          return VerificationOtpPhone.route(routeSettings);
        }
      case dashboard:
        {
          return DashboardScreen.route(routeSettings);
        }
      case home:
        {
          return DashboardScreen.route(routeSettings);
        }
      case googleSignUpForm:
        {
          return GoogleSignUpForm.route(routeSettings);
        }
      case subscriptionDetailPlan:
        {
          return SubscriptionDetailScreen.route(routeSettings);
        }
      case hardCopySubscriptionDetailPlan:
        {
          return HardCopySubscriptionDetailScreen.route(routeSettings);
        }
      case selectedSubscriptionPlanScreen:
        {
          return SelectedSubscriptionPlanScreen.route(routeSettings);
        }
      case selectBookAndSubscriptionDetail:
        {
          return SelectBookAndSubscriptionDetailScreen.route(routeSettings);
        }
      case showTestScreen:
        {
          return ShowTestScreen.route(routeSettings);
        }
      case videoLectures:
        {
          return VideoLecturesScreen.route(routeSettings);
        }
      case VideoTopicCategory:
        {
          return VideoTopicCategoryScreen.route(routeSettings);
        }
      case videoSubjectDetail:
        {
          return VideoSubjectDetail.route(routeSettings);
        }
      case videoChapterDetail:
        {
          return VideoChapterDetail.route(routeSettings);
        }
      case videoPlayDetail:
        {
          return VideoPlayerDetail.route(routeSettings);
        }
      case notesCategory:
        {
          return NotesScreen.route(routeSettings);
        }
      case notesTopicCategory:
        {
          return NotesTopicCategoryScreen.route(routeSettings);
        }
      case notesSubjectDetail:
        {
          return NotesSubjectDetail.route(routeSettings);
        }
      case notesChapterDetail:
        {
          return NotesChapterDetail.route(routeSettings);
        }
      case testCategory:
        {
          return TestCategoryScreen.route(routeSettings);
        }
      case allTestCategory:
        {
          return AllTestCategoryScreen.route(routeSettings);
        }
      case testSubjectDetail:
        {
          return TestsSubjectDetail.route(routeSettings);
        }
      case chooseTestScreen:
        {
          return ChooseTestScreen.route(routeSettings);
        }
      case testChapterDetail:
        {
          return TestChapterDetail.route(routeSettings);
        }
      case testReportScreen:
        {
          return TestReportScreen.route(routeSettings);
        }
      case customTestReportScreen:
        {
          return CustomTestReportScreen.route(routeSettings);
        }
      case testReportDetailsScreen:
        {
          return TestReportDetailsScreen.route(routeSettings);
        }
      case customTestReportDetailsScreen:
        {
          return CustomTestReportDetailsScreen.route(routeSettings);
        }
      case masterTestReportDetailsScreen:
        {
          return MasterTestReportDetailsScreen.route(routeSettings);
        }
      case masterTestReportScreen:
        {
          return MasterTestReportScreen.route(routeSettings);
        }
      case selectTestList:
        {
          return SelectTestList.route(routeSettings);
        }
      case allSelectTestList:
        {
          return AllSelectTestList.route(routeSettings);
        }
      case startSectionInstructionScreen:
        {
          return StartSectionInstructionScreen.route(routeSettings);
        }
      case testExams:
        {
          return TestExamScreen.route(routeSettings);
        }
      case customTestExams:
        {
          return CustomTestExamScreen.route(routeSettings);
        }
      case testMasterExams:
        {
          return TestMasterExamScreen.route(routeSettings);
        }
      case quizTestExamScreen:
        {
          return QuizTestExamScreen.route(routeSettings);
        }
      case featuredTestExamPage:
        {
          return FeaturedTestExamPage.route(routeSettings);
        }
      case practiceTestExams:
        {
          return PracticeTestExamScreen.route(routeSettings);
        }
      case practiceCustomTestExamScreen:
        {
          return PracticeCustomTestExamScreen.route(routeSettings);
        }
      case practiceSolutionTestExams:
        {
          return PracticeTestSolutionExamScreen.route(routeSettings);
        }
      case mockPracticeSolutionTestExams:
        {
          return MockPracticeTestSolutionExamScreen.route(routeSettings);
        }
      case practiceSolutionCustomTestExams:
        {
          return PracticeCustomTestSolutionExamScreen.route(routeSettings);
        }
      case practiceMasterTestExams:
        {
          return PracticeMasterTestExamScreen.route(routeSettings);
        }
      case notesReadView:
        {
          return NotesReadView.route(routeSettings);
        }
      case reportList:
        {
          return ReportListScreen.route(routeSettings);
        }
      case selectExamReportList:
        {
          return SelectExamReportList.route(routeSettings);
        }
      case selectMasterExamReportList:
        {
          return SelectMasterExamReportList.route(routeSettings);
        }
      case reportSubCategory:
        {
          return ReportSubCategory.route(routeSettings);
        }
      case customTestReportSubCategory:
        {
          return CustomTestReportSubCategory.route(routeSettings);
        }
      case masterReport:
        {
          return MasterReport.route(routeSettings);
        }
      case bookMarkList:
        {
          return BookMarkMainListScreen.route(routeSettings);
        }
      case bookMarkExamList:
        {
          return SelectBookMarkExamList.route(routeSettings);
        }
      case masterBookMarkExamList:
        {
          return SelectMasterBookMarkExamList.route(routeSettings);
        }
      case bookMarkExamAttemptList:
        {
          return BookMarkExamAttemptList.route(routeSettings);
        }
      case bookMarkQuestionList:
        {
          return BookMarkQuestionList.route(routeSettings);
        }
      case bookMarkQuestionDetail:
        {
          return BookMarkQuestionDetailScreen.route(routeSettings);
        }
      case masterBookMarkQuestionDetail:
        {
          return MasterBookMarkQuestionDetailScreen.route(routeSettings);
        }
      case solutionReport:
        {
          return SolutionReportScreen.route(routeSettings);
        }
      case customTestSolutionReport:
        {
          return CustomTestSolutionReportScreen.route(routeSettings);
        }
      case solutionMasterReport:
        {
          return SolutionMasterReportScreen.route(routeSettings);
        }
      case sprReportList:
        {
          return SPRReportsListScreen.route(routeSettings);
        }
      case sprReportDetail:
        {
          return SPRReportDetailScreen.route(routeSettings);
        }
      case reportMainScreen:
        {
          return ReportMainScreen.route(routeSettings);
        }
      case masterReportMainScreen:
        {
          return MasterReportMainScreen.route(routeSettings);
        }
      case editProfile:
        {
          return EditProfile.route(routeSettings);
        }
      case verifyChangeMobileOtp:
        {
          return VerifyChangeMobileOtp.route(routeSettings);
        }
      case downloadedNotes:
        {
          return DownloadedNotes.route(routeSettings);
        }
      case downloadedNotesCategory:
        {
          return OfflineCategoryList.route(routeSettings);
        }
      case downloadedNotesSubCategory:
        {
          return OfflineSubCategoryList.route(routeSettings);
        }
      case downloadedNotesTopic:
        {
          return OfflineTopicList.route(routeSettings);
        }
      case downloadedNotesTitle:
        {
          return OfflineTitleList.route(routeSettings);
        }
      case featuredNotes:
        {
          return FeaturedNotesView.route(routeSettings);
        }
      case featuredVideos:
        {
          return FeaturedVideoView.route(routeSettings);
        }
      case paymentStatus:
        {
          return PaymentSuccessfulScreen.route(routeSettings);
        }
      case paymentFailed:
        {
          return PaymentFailedScreen.route(routeSettings);
        }
      case notificationScreen:
        {
          return NotificationsScreen.route(routeSettings);
        }
      case sectionquestionPallet:
        {
          return SectionQuestionPallet.route(routeSettings);
        }
      case testNotificationScreen:
        {
          return TestNotificationsScreen.route(routeSettings);
        }
      case solutionTestNotificationScreen:
        {
          return SolutionTestNotificationsScreen.route(routeSettings);
        }
      case masterTestNotificationScreen:
        {
          return MasterTestNotificationsScreen.route(routeSettings);
        }
      case customTestSelectCategory:
        {
          return SelectCustomTestsCategory.route(routeSettings);
        }
      case customTestSelectChapter:
        {
          return SelectCustomTestsChapter.route(routeSettings);
        }
      case customTestSelectTopic:
        {
          return SelectCustomTestsTopic.route(routeSettings);
        }
      case customTestSelectTest:
        {
          return SelectTestCustomTest.route(routeSettings);
        }
      case customConfiguration:
        {
          return CustomConfiguration.route(routeSettings);
        }
      case blogScreen:
        {
          return BlogScreen.route(routeSettings);
        }
      case blogDetailsScreen:
        {
          return BlogDetailsScreen.route(routeSettings);
        }
      case testimonialScreen:
        {
          return TestimonialScreen.route(routeSettings);
        }
      case quizScreen:
        {
          return QuizScreen.route(routeSettings);
        }
      case quizSolutionScreen:
        {
          return QuizSolutionScreen.route(routeSettings);
        }
      case quizSolutionReportScreen:
        {
          return QuizSolutionReportScreen.route(routeSettings);
        }
      case customPreview:
        {
          return CustomPreview.route(routeSettings);
        }
      case customTestList:
        {
          return CustomTestLists.route(routeSettings);
        }
      case bookMarkCategoryList:
        {
          return BookMarkCategoryScreen.route(routeSettings);
        }
      case masterBookMarkCategoryList:
        {
          return MasterBookMarkCategoryScreen.route(routeSettings);
        }
      case bookMarkSubcategoryList:
        {
          return BookMarkSubcategoryScreen.route(routeSettings);
        }
      case bookMarkTopicList:
        {
          return BookMarkTopicScreen.route(routeSettings);
        }
      case reportsCategoryList:
        {
          return ReportCategoryScreen.route(routeSettings);
        }
      case masterReportsCategoryList:
        {
          return MasterReportCategoryScreen.route(routeSettings);
        }
      case reportsSubCategoryList:
        {
          return ReportsSubcategoryScreen.route(routeSettings);
        }
      case reportsTopicList:
        {
          return ReportTopicScreen.route(routeSettings);
        }
      case aboutus:
        {
          return AboutScreen.route(routeSettings);
        }
      case liveClassMainScreen:
        {
          return LiveClassMainScreen.route(routeSettings);
        }
      case liveClasses:
        {
          return LiveClass.route(routeSettings);
        }
      case liveClassesUpcoming:
        {
          return LiveClassesUpcoming.route(routeSettings);
        }
      case liveClassesCompleted:
        {
          return LiveClassesCompleted.route(routeSettings);
        }
      case addressDetailScreen:
        {
          return AddressDetailScreen.route(routeSettings);
        }
      case viewNoteDetails:
        {
          return ViewNoteDetailsScreen.route(routeSettings);
        }
      case viewHardCopyNoteDetails:
        {
          return ViewHardCopyNoteDetailsScreen.route(routeSettings);
        }
      case bookListScreen:
        {
          return BookListScreen.route(routeSettings);
        }
      case hardCopyAddressScreen:
        {
          return HardCopyAddressDetailScreen.route(routeSettings);
        }
      case hardCopyAndSubscriptionAddressScreen:
        {
          return HardCopyAndSubscriptionAddressDetailScreen.route(routeSettings);
        }
      case hardCopySubscriptionListScreen:
        {
          return HardCopySubscriptionList.route(routeSettings);
        }
      case searchScreen:
        {
          return SearchScreen.route(routeSettings);
        }
      case continueWatchingScreen:
        {
          return ContinueWatchingScreen.route(routeSettings);
        }
      case progressScreen:
        {
          return ProgressScreen.route(routeSettings);
        }
      case newPaymentSuccess:
        {
          return PaymentSuccessScreen.route(routeSettings);
        }
      case trackOrder:
        {
          return TrackOrderScreen.route(routeSettings);
        }
      case purchaseHardcopy:
        {
          return PurchaseHardcopyScreen.route(routeSettings);
        }
      case hardcopyDetails:
        {
          return HardcopyDetailsScreen.route(routeSettings);
        }
      case volumeIndex:
        {
          return VolumeIndexScreen.route(routeSettings);
        }
      case chapterDetails:
        {
          return ChapterDetailsScreen.route(routeSettings);
        }
      case orderedBookListScreen:
        {
          return CupertinoPageRoute(
            builder: (_) => Provider<OrderedBookStore>(
              create: (_) => OrderedBookStore(),
              child: const OrderedBookListScreen(),
            ),
          );
        }
      case selectUpgradePlan:
        {
          final args = routeSettings.arguments as Map<String, dynamic>?;
          return CupertinoPageRoute(
            builder: (_) => SelectUpgradePlanScreen(
              subscriptionId: args?['subscriptionId'] ?? '',
              sameValidity: args?['sameValidity'] ?? false,
              isDiffValidity: args?['isDiffValidity'] ?? false,
            ),
          );
        }
      case deleteHistoryScreen:
        {
          return DeleteHistoryScreen.route(routeSettings);
        }
      case preparingForScreen:
        {
          return PreparingForScreen.route(routeSettings);
        }
      case reviewQueue:
        {
          return ReviewQueueScreen.route(routeSettings);
        }
      // Cortex AI v2/v3 routes
      case cortexHome:
        {
          return CortexHomeScreen.route(routeSettings);
        }
      case cortexChat:
        {
          return CortexChatScreen.route(routeSettings);
        }
      case cortexModeStart:
        {
          return CortexModeStartScreen.route(routeSettings);
        }
      case cortexMemory:
        {
          return CortexMemoryScreen.route(routeSettings);
        }
      case cortexSnippets:
        {
          return CortexSnippetsScreen.route(routeSettings);
        }
      // MCQ Review v3 routes
      case reviewQueueV3:
        {
          return ReviewQueueScreen.route(routeSettings);
        }
      case studyPlan:
        {
          return StudyPlanScreen.route(routeSettings);
        }
      case scheduledSessions:
        {
          return ScheduledSessionsScreen.route(routeSettings);
        }
      case performanceTrends:
        {
          return PerformanceTrendsScreen.route(routeSettings);
        }
      case readingSettings:
        {
          return ReadingSettingsScreen.route(routeSettings);
        }
      default:
        {
          return CupertinoPageRoute(builder: (context) => const Scaffold());
        }
    }
  }
}
