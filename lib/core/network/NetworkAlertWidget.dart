import 'package:flutter/material.dart';
import 'package:shusruta_lms/helpers/colors.dart';
import 'package:shusruta_lms/core/network/network_service.dart';

class NetworkAlertWidget {
  static bool _isDialogShowing = false;

  static void showNetworkAlert({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onRetry,
  }) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return GestureDetector(
          onTap: () => hideDialog(context),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: GestureDetector(
                onTap: () {},
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Container(
                      width: 200,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          const SizedBox(width: 5),
                          Icon(icon, color: color, size: 17),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });

    // Auto-dismiss only when connection is back online
    NetworkService().connectionStatusStream.listen((status) {
      if (status == ConnectionStatus.online) {
        hideDialog(context);
      }
    });
  }

  static void showOfflineAlert(BuildContext context, {VoidCallback? onRetry}) {
    showNetworkAlert(
      context: context,
      title: 'No Internet Connection',
      icon: Icons.wifi_off,
      color: Colors.white,
      onRetry: onRetry,
    );
  }

  static void hideDialog(BuildContext context) {
    if (_isDialogShowing) {
      _isDialogShowing = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
