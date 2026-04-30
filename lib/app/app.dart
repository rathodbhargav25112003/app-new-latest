import 'dart:io';
import 'dart:ui';
import 'dart:ffi';
import 'routes.dart';
import '../helpers/colors.dart';
import '../helpers/dbhelper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../modules/login/store/login_store.dart';
import 'package:firebase_core/firebase_core.dart';
import '../modules/signup/store/signup_store.dart';
import 'package:shusruta_lms/firebase_options.dart';
import 'package:window_manager/window_manager.dart';
import '../modules/dashboard/store/home_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:screen_protector/screen_protector.dart';
import '../modules/bookmarks/store/bookmark_store.dart';
import '../modules/test/store/test_category_store.dart';
import '../modules/notes/store/notes_category_store.dart';
import '../modules/customtests/store/custom_test_store.dart';
import '../modules/dashboard/store/internet_check_store.dart';
import '../modules/reports/store/report_by_category_store.dart';
import '../modules/videolectures/store/video_category_store.dart';
import '../modules/subscriptionplans/store/subscription_store.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shusruta_lms/modules/new_exam_component/store/exam_store.dart';
import 'package:shusruta_lms/modules/new-bookmark-flow/store/new_bookmark_store.dart';
import 'package:shusruta_lms/modules/liveclass/store/live_class_main_screen_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/new_subscription_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/subscription_plan_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/store/ordered_book_store.dart';
import 'package:shusruta_lms/modules/cortex/store/cortex_store.dart';

import 'package:shusruta_lms/modules/masterTest/sectionwisemasterTest/store/section_exam_store.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

isWindows() {
  return (Platform.isWindows || Platform.isMacOS);
}

Future<void> initializeApp() async {
  // WebView.platform = WebWebViewPlatform();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FFI
  sqfliteFfiInit();
  await windowManager.ensureInitialized();

  databaseFactory = databaseFactoryFfi;
  final dbHelper = DbHelper();
  await dbHelper.initDatabase(); // Ensures database is initialized
  await ThemeManager.loadTheme();

  // Initialize Crashlytics
  // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Optionally, catch errors outside Flutter
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
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
        Provider<NewSubscriptionStore>(create: (_) => NewSubscriptionStore()),
        Provider<SubscriptionPlanStore>(create: (_) => SubscriptionPlanStore()),
        Provider<OrderedBookStore>(create: (_) => OrderedBookStore()),
        Provider<SectionExamStore>(create: (_) => SectionExamStore()),
        Provider<BookmarkNewStore>(create: (_) => BookmarkNewStore()),
        // Cortex AI v2/v3 store — multi-turn chat, memory, snippets, modes
        Provider<CortexStore>(create: (_) => CortexStore()),
      ],
      child: Consumer<ThemeNotifier>(builder: (context, themeNotifier, _) {
        return DisableCopyPaste(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Home Page',
            scrollBehavior: NoThumbScrollBehavior().copyWith(scrollbars: false),
            theme: ThemeData(
                fontFamily: 'Jost',
                hoverColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                primaryColor: AppColors.primaryColor,
                highlightColor: Colors.transparent,
                disabledColor: AppColors.btnGrey,
                hintColor: AppColors.hintColor,
                iconButtonTheme: const IconButtonThemeData(
                    style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                )),
                colorScheme: ColorScheme.fromSwatch()
                    .copyWith(secondary: AppColors.backgroundGrey)
                    .copyWith(surface: AppColors.backgroundColor)),
            darkTheme: ThemeData(
                fontFamily: 'Jost',
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                primaryColor: AppColorsDark.primaryColor,
                highlightColor: Colors.transparent,
                disabledColor: AppColorsDark.btnGrey,
                hintColor: AppColorsDark.hintColor,
                iconButtonTheme: const IconButtonThemeData(
                    style: ButtonStyle(
                  splashFactory: NoSplash.splashFactory,
                )),
                colorScheme: ColorScheme.fromSwatch()
                    .copyWith(secondary: AppColorsDark.backgroundGrey)
                    .copyWith(surface: AppColorsDark.backgroundColor)),
            themeMode: themeNotifier.currentTheme == AppTheme.Dark
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: Routes.mainSplash,
            onGenerateRoute: Routes.onGenerateRouted,
          ),
        );
      }),
    );
  }
}

/// Custom widget to disable copy/paste globally
class DisableCopyPaste extends StatelessWidget {
  final Widget child;

  const DisableCopyPaste({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        // Disable copy (Ctrl+C / Cmd+C)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
            const NoopIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC):
            const NoopIntent(),
        // Disable paste (Ctrl+V / Cmd+V)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
            const NoopIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyV):
            const NoopIntent(),
        // Disable cut (Ctrl+X / Cmd+X)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX):
            const NoopIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyX):
            const NoopIntent(),
        // Disable select all (Ctrl+A / Cmd+A)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const NoopIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyA):
            const NoopIntent(),
      },
      child: Actions(
        actions: {
          NoopIntent: CallbackAction<NoopIntent>(
            onInvoke: (intent) {
              // Do nothing when the shortcut is triggered
              return null;
            },
          ),
        },
        child: Listener(
          onPointerDown: (_) {
            // Hide the context menu when right-clicking or long-pressing
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          child: child,
        ),
      ),
    );
  }
}

/// A no-op intent to block shortcuts
class NoopIntent extends Intent {
  const NoopIntent();
}

// For hide ScrollBehavior
class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
