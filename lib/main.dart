import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:pspdfkit_flutter/pspdfkit.dart';

import 'package:nutrient_flutter/pspdfkit_flutter.dart';
import 'package:shusruta_lms/app/phone_app.dart';

import 'app/app.dart';
import 'services/download_service.dart';
// import 'package:pspdfkit_flutter/pspdfkit.dart';
import 'services/root_guard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter binding is initialized first

  // Add a small delay to ensure platform channels are properly set up
  await Future.delayed(const Duration(milliseconds: 200));
  try {
    // Use the default Pigeon-based approach
    await Pspdfkit.initialize(
      androidLicenseKey:
          'fJ4HXjgLziDBiM5_HJhQbxD-VBjuc4yYfPZCzAVst-KtGF9YzQlAkC5erDBbcrHsn9pMeCdrJzV8eJbjrdrxZVNswamkB9abFdU-Pe99yn938AzxLEFGgbhQ6Gixp_ayFpBIlMCoSjmdltciDO7NQJYkf9ZiJyE-E-HRmg7lfQE6LIRKjaJOfl9r3MmVMeOKpiqNDDzYnxL6DpCWdWpwfZpiTfPukyvCerpbU1lXdB14ROVdoPxhGFzWfgBChWrLyajfnmSry7TMGnZu3hd80VHZr6DKsG5il4lASns7BlK_Oc-yzXZXelNZfoxtFPIxUwKXOtl-mw4u2_LInZYNnyOJYGyNL2x9lw8oO9pnK93RXdZYPqeHqLRvZ1n3P8maXYh-PX6K_2i6ug8uI9nKH-9jmiI0XOCmUHtevMWfhA_6FQmnre2PxqtK9Y0GBlWUd9-UCM_NJtcaHz6SBUrJ_P_V3ugaKYWSPYTTAz5AcZNbT4oC3fEKd7sn1SCqElSWshcHFn-bSpNrncEKt-tGQrgLiNJiLDeblTSgM0AoLm9DHJmNjuUj8yx3KRaZ1X-BQsBlgJOtHB5CXQYGTKt99x0d20r9n3qtn0yLQg_IZWI=',
      iosLicenseKey:
          'DGq2GdV2W7Qt5NZ3KGQ0V_uSDIfaS7lnKo9c9foCOxW3tIthd81_R6keag9xJAesWSip2Gb3zsqX2vDqcWCmtsAYEXPz4OQ6Zo3Yy93lrDzQAkp1gQozcMB2Quluh7paI31yyvLhHnUlsq0GCC8mpbRYvZ6zFdsCgsr4b2lhfOHulp2S3Pk7WMIKUV3VoBCigZxnmGAUzUCI4iD_Ed4Bpb8NRJGyS1_a0t-NDNVI9OEE7nIP0C6Zdys_PVt0v-o4DnO2RWT4fsMsFFmHtG8JGsK0iB59WV3FJR46e62YB6W2iay_IBKVmiwNPpgjI0chkvv8TSejpw3zrnoWFLEn71pY8aNXtNcUkVZRvqKLgBORRBElP1esN4N3_cZPNzUTYBLE5JxZIHwI7ZBDp0zZwh0Sv8dycLgSL2yAMCvn4RZxT1xH6nA_LLZ4Rd74L2L80I2L1m29CwhSJ-_Hw0OFfQeXbyzdH-oQD69q2ztYUuuhVz9bshxD9w0CrJ-msv4hoAMDNFEidoOmoG9fb241gbDdF4m4SOqBC_KW02X1QW53D23mBojJMpYIUcyHJP-v2oe5woWNNXjZ8-yimZ8JXxAHRY9BXbVc92ZvvBpnUdQ=',
    );
  } catch (e) {
    print('PSPDFKit initialization failed: $e');
    // Continue with app initialization even if PSPDFKit fails
  }

  // Rooted-device gate: block and wipe before app starts
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      final rooted = await RootGuard.isDeviceRooted();
      if (rooted) {
        runApp(const _RootBlockedApp());
        return;
      }
    }
  } catch (_) {}

  // Initialize download service — cleans temp files, loads WiFi-only pref
  await DownloadService.instance.init();

  Platform.isIOS || Platform.isAndroid ? initializePhoneApp() : initializeApp();
}

// Minimal app that shows a blocking screen if the device is rooted.
class _RootBlockedApp extends StatelessWidget {
  const _RootBlockedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.security, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Security Alert',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This device appears to be rooted/jailbroken.\nFor your data protection, the app will clear local data and exit.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        try {
                          await RootGuard.wipeAppData();
                        } catch (_) {}
                        await RootGuard.quitApp();
                      },
                      child: const Text('Quit'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// @pragma("vm:entry-point")
// void overlayPopUp() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp( MaterialApp(
//     theme: ThemeData.light(useMaterial3:true),

//     home: OverlayWidget(),
//   ));
// }
//
// int customeheight = 400;
// int customewidth = 400;
//
// class OverlayWidget extends StatelessWidget {
//   const OverlayWidget({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final GlobalKey<SfPdfViewerState> _pdfOverlayViewer = GlobalKey();
//
//     return StreamBuilder(
//       stream: OverlayPopUp.dataListener,
//       builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
//         if (snapshot.data['pdf'].toString().isEmpty) {
//           return Scaffold(
//               appBar: AppBar(
//                 leading: Icon(Icons.drag_handle_outlined),
//                 title: Text(snapshot.data['title'] ?? "Pdf Viewer"),
//                 centerTitle: true,
//                 actions: [
//                         IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
//                       onPressed: () {
//                         if (550 > customeheight || 450 > customewidth) {
//                           OverlayPopUp.updateOverlaySize(
//                               height: customeheight += 50,
//                               width: customewidth += 50);
//                         } else if(customewidth==500 && customeheight==600) {
//                           OverlayPopUp.updateOverlaySize(
//                               height: customeheight,
//                               width: customewidth);
//                         }
//                         else{
//                           OverlayPopUp.updateOverlaySize(
//                               height: customeheight -= 50,
//                               width: customewidth -= 50);
//                         }
//                         print("customeheight $customeheight");
//                         print("customewidth $customewidth");
//                       },
//                       icon: Icon(Icons.photo_size_select_small_rounded)),
//                         IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
//                       onPressed: () {
//                         OverlayPopUp.closeOverlay();
//                       },
//                       icon: Icon(Icons.close)),
//                 ],
//               ),
//               body: Center(child: Text("Pdf Not available")));
//         } else {
//           return Scaffold(
//             appBar: AppBar(
//               leading: Icon(Icons.drag_handle_outlined),
//               title: Text(snapshot.data['title'] ?? "Pdf Viewer", style: interRegular.copyWith(
//                 fontSize: Dimensions.fontSizeLarge,
//                 fontWeight: FontWeight.w400,
//                 color: ThemeManager.black,
//               ),),
//               centerTitle: true,
//               actions: [
//                       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
//                     onPressed: () {
//                       if (650 > customeheight || 450 > customewidth) {
//                         OverlayPopUp.updateOverlaySize(
//                             height: customeheight += 50,
//                             width: customewidth += 50);
//                       } else {
//                         OverlayPopUp.updateOverlaySize(
//                             height: customeheight -= 50,
//                             width: customewidth -= 50);
//                       }
//                     },
//                     icon: Icon(Icons.photo_size_select_small_rounded)),
//                       IconButton(       highlightColor: Colors.transparent,     hoverColor: Colors.transparent,
//                     onPressed: () {
//                       OverlayPopUp.closeOverlay();
//                     },
//                     icon: Icon(Icons.close)),
//               ],
//             ),
//             body: SfPdfViewer.network(
//                 key: _pdfOverlayViewer,
//                 pdfBaseUrl +
//                     "getPDF${snapshot.data['pdf'].substring(snapshot.data['pdf'].lastIndexOf('/'))}"),
//           );
//         }
//       },
//     );
//   }
// }
