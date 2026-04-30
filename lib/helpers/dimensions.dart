import 'package:get/get.dart';
import 'package:shusruta_lms/app/routes.dart';

class Dimensions {
  static double get fontSizeExtraSmall =>
      (Get.context?.width ?? 0) >= 1300 ? 14 : 10;

  static double get fontSizeSmall =>
      (Get.context?.width ?? 0) >= 1300 ? 16 : 12;

  static double get fontSizeSmallLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 17 : 13;

  static double get fontSizeDefault =>
      (Get.context?.width ?? 0) >= 1300 ? 18 : 14;

  static double get fontSizeDefaultLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 19 : 15;

  static double get fontSizeLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 20 : 16;

  static double get fontSizeExLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 21 : 17;

  static double get fontSizeExtraLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 23 : 18;

  static double get fontSizeExtraExtraLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 25 : 20;

  static double get fontSizeSmallOverLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 27 : 22;

  static double get fontSizeDefaultOverLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 28 : 23;

  static double get fontSizeOverLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 28 : 24;

  static double get fontSizeOverLargeLarge =>
      (Get.context?.width ?? 0) >= 1300 ? 32 : 28;

  static double calculateFontSize(double width) {
    if (width >= 1300) {
      return fontSizeDefault;
    } else {
      return fontSizeSmall;
    }
  }
  static const double PADDING_SIZE_EXTRA_SMALL = 5.0;
  static const double PADDING_SIZE_SMALL = 10.0;
  static const double PADDING_SIZE_DEFAULT = 15.0;
  static const double PADDING_SIZE_LARGE = 20.0;
  static const double PADDING_SIZE_EXTRA_LARGE = 25.0;
  static const double paddingSizeLarge = 20.0; // Make sure this exists

  static const double RADIUS_SMALL = 5.0;
  static const double RADIUS_DEFAULT = 10.0;
  static const double RADIUS_LARGE = 15.0;
  static const double RADIUS_EXTRA_LARGE = 20.0;

  static const double WEB_MAX_WIDTH = 1170;
  static const int MESSAGE_INPUT_LENGTH = 250;
}
