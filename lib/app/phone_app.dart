import 'dart:async';
import 'dart:io';
import '../core/network/NetworkAlertWidget.dart';
import '../core/network/network_service.dart';
import '../modules/videolectures/custom_vimeo_player_window.dart';
import 'routes.dart';
import 'dart:developer';
import '../helpers/colors.dart';
import '../helpers/dbhelper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import '../modules/login/store/login_store.dart';
import 'package:firebase_core/firebase_core.dart';
import '../modules/signup/store/signup_store.dart';
import '../modules/dashboard/store/home_store.dart';
import 'package:screen_protector/screen_protector.dart';
import '../modules/bookmarks/store/bookmark_store.dart';
import '../modules/test/store/test_category_store.dart';
import '../modules/notes/store/notes_category_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modules/customtests/store/custom_test_store.dart';
import '../modules/dashboard/store/internet_check_store.dart';
import '../modules/reports/store/report_by_category_store.dart';
import '../modules/videolectures/store/video_category_store.dart';
import '../modules/subscriptionplans/store/subscription_store.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';
import 'package:shusruta_lms/modules/liveclass/store/live_class_main_screen_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/subscription_plan_store.dart';
import '../modules/orders/store/order_store.dart';
import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/store/section_exam_store.dart';



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializePhoneApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // final dbHelper = DbHelper();
  // await dbHelper.initDatabase();
  await Upgrader.clearSavedSettings();
  await initializeNotifications();
  await ThemeManager.loadTheme();
  runApp(ChangeNotifierProvider(
    create: (context) => ThemeNotifier(),
    child: const MyApp(),
  ));
  // SystemChrome.setSystemUIOverlayStyle( SystemUiOverlayStyle(
  //   statusBarColor: Colors.transparent,
  //   statusBarIconBrightness: ThemeManager.currentTheme == AppTheme.Dark ? Brightness.light : Brightness.dark,
  //     statusBarBrightness: ThemeManager.currentTheme == AppTheme.Dark ? Brightness.dark : Brightness.light,
  // ));
}

Future<void> requestIOSPermissions() async {
  final bool? result = await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  debugPrint("Notification permission granted: $result");
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidInitializationSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInitializationSettings =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitializationSettings,
    iOS: iosInitializationSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  requestIOSPermissions();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
} 

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NetworkService _networkService = NetworkService();
  StreamSubscription<ConnectionStatus>? _networkSubscription;
  ConnectionStatus _lastShownStatus = ConnectionStatus.online;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    ScreenProtector.protectDataLeakageOn();
    WidgetsBinding.instance.addObserver(this);
    _initializeNetworkService();
    disableSS();
  }

  Future<void> _initializeNetworkService() async {
    await _networkService.initialize();

    _networkSubscription = _networkService.connectionStatusStream.listen(
      _handleNetworkStatusChange,
    );
  }

  void _handleNetworkStatusChange(ConnectionStatus status) {
    // Only show alert if status actually changed
    if (_lastShownStatus == status) return;

    _lastShownStatus = status;

    // Get current context
    final context = navigatorKey.currentContext;
    if (context == null) return;

    switch (status) {
      case ConnectionStatus.offline:
        NetworkAlertWidget.showOfflineAlert(
          context,
          onRetry: () => _networkService.updateConnectionStatus(),
        );
        break;

      case ConnectionStatus.online:
      // Hide any showing dialog when connection is restored
        NetworkAlertWidget.hideDialog(context);
        // You can show a success snackbar if needed
        _showConnectedSnackbar(context);
        break;
    }
  }

  void _showConnectedSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 10),
            Text('Internet connection restored'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Re-check network when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _networkService.updateConnectionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _networkSubscription?.cancel();
    _networkService.dispose();
    super.dispose();
  }

  void disableSS() async {
    if (Platform.isAndroid) {
      await ScreenProtector.protectDataLeakageOn();
    } else if (Platform.isIOS) {
      await ScreenProtector.preventScreenshotOn();
    }
  }

  @override
  Widget build(BuildContext context) {
    // secureScreen();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        //ChangeNotifierProvider(create: ZoomMeetingProvider)<ZoomMeetingProvider>(create:(_)=>ZoomMeetingProvider()),
        Provider<MeetingStore>(create: (_) => MeetingStore()),
        Provider<InternetStore>(create: (_) => InternetStore()),
        Provider<SignupStore>(create: (_) => SignupStore()),
        Provider<LoginStore>(create: (_) => LoginStore()),
        Provider<SubscriptionStore>(create: (_) => SubscriptionStore()),
        Provider<VideoCategoryStore>(create: (_) => VideoCategoryStore()..wireDownloadService()),
        Provider<TestCategoryStore>(create: (_) => TestCategoryStore()),
        Provider<CustomTestCategoryStore>(
            create: (_) => CustomTestCategoryStore()),
        Provider<NotesCategoryStore>(create: (_) => NotesCategoryStore()),
        Provider<ReportsCategoryStore>(create: (_) => ReportsCategoryStore()),
        Provider<BookMarkStore>(create: (_) => BookMarkStore()),
        Provider<HomeStore>(create: (_) => HomeStore()),
        Provider<ExamStore>(create: (_) => ExamStore()),
        Provider<SubscriptionPlanStore>(create: (_) => SubscriptionPlanStore()),
        Provider<OrderStore>(create: (_) => OrderStore()),
        Provider<SectionExamStore>(create: (_) => SectionExamStore()),
        Provider<BookmarkNewStore>(create: (_) => BookmarkNewStore()),
      ],
      child: Consumer<ThemeNotifier>(builder: (context, themeNotifier, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Home Page',
          theme: ThemeData(
              fontFamily: 'Jost',
              appBarTheme: AppBarTheme(elevation: 0),
              useMaterial3: false,
              primaryColor: AppColors.primaryColor,
              disabledColor: AppColors.btnGrey,
              hintColor: AppColors.hintColor,
              colorScheme: ColorScheme.fromSwatch()
                  .copyWith(secondary: AppColors.backgroundGrey)
                  .copyWith(surface: AppColors.backgroundColor)),
          darkTheme: ThemeData(
              fontFamily: 'Jost',
              useMaterial3: false,
              primaryColor: AppColorsDark.primaryColor,
              disabledColor: AppColorsDark.btnGrey,
              hintColor: AppColorsDark.hintColor,
              colorScheme: ColorScheme.fromSwatch()
                  .copyWith(secondary: AppColorsDark.backgroundGrey)
                  .copyWith(surface: AppColorsDark.backgroundColor)),
          themeMode: themeNotifier.currentTheme == AppTheme.Dark
              ? ThemeMode.dark
              : ThemeMode.light,
          initialRoute: Routes.mainSplash,
          onGenerateRoute: Routes.onGenerateRouted,
        );
      }),
    );
  }

  // Future<void> secureScreen() async {
  //   await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  // }
}
