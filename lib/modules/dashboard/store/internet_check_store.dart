import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobx/mobx.dart';

part 'internet_check_store.g.dart';

class InternetStore = _InternetStore with _$InternetStore;

abstract class _InternetStore with Store {
  // Optimistic default — assume connected until a real probe says otherwise.
  //
  // Rationale: every store that extends InternetStore used to initialise this
  // flag to `false`. Screens gate their content on `isConnected`, so the
  // first frame of HomeScreen (and every other gated screen) rendered the
  // NoInternetScreen *before* any API call had a chance to run
  // `checkConnectionStatus()`. On fast networks the flip happened within a
  // frame or two — on the Android emulator (cold start, slow connectivity
  // reply) it persisted long enough to look like a blank viewport with the
  // bottom nav floating mid-screen (NoInternetScreen's `Center` column
  // centers vertically, pushing the outer Scaffold's bottomNavigationBar up
  // because the body region is un-scrolled and the content column is tiny).
  // Defaulting to `true` makes the first paint render real content and the
  // probe below flips to `false` only when we actually detect offline.
  @observable
  bool isConnected = true;

  @action
  Future<void> checkConnectionStatus() async {
    // var connectivityResult = await (Connectivity().checkConnectivity());
    final List<ConnectivityResult> connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setConnectionStatus(false);
    } else {
      setConnectionStatus(true);
    }
    debugPrint("connectivityResult:$connectivityResult");
  }

  @action
  void setConnectionStatus(bool status) {
    isConnected = status;
  }
}