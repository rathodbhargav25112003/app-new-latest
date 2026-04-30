// import 'package:connectivity/connectivity.dart';
// import 'package:mobx/mobx.dart';
//
// part 'internet_check_store.g.dart';
//
// class InternetStore = _InternetStore with _$InternetStore;
//
// abstract class _InternetStore with Store {
//   @observable
//   bool isConnected = false;
//
//   @action
//   Future<void> checkConnectionStatus() async {
//     var connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       setConnectionStatus(false);
//     } else {
//       setConnectionStatus(true);
//     }
//   }
//
//   @action
//   void setConnectionStatus(bool status) {
//     isConnected = status;
//   }
// }