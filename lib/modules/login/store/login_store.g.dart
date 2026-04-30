// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LoginStore on _LoginStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_LoginStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$isRemoveLoadingAtom =
      Atom(name: '_LoginStore.isRemoveLoading', context: context);

  @override
  bool get isRemoveLoading {
    _$isRemoveLoadingAtom.reportRead();
    return super.isRemoveLoading;
  }

  @override
  set isRemoveLoading(bool value) {
    _$isRemoveLoadingAtom.reportWrite(value, super.isRemoveLoading, () {
      super.isRemoveLoading = value;
    });
  }

  late final _$isLoadingSettingsAtom =
      Atom(name: '_LoginStore.isLoadingSettings', context: context);

  @override
  bool get isLoadingSettings {
    _$isLoadingSettingsAtom.reportRead();
    return super.isLoadingSettings;
  }

  @override
  set isLoadingSettings(bool value) {
    _$isLoadingSettingsAtom.reportWrite(value, super.isLoadingSettings, () {
      super.isLoadingSettings = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_LoginStore.errorMessage', context: context);

  @override
  String get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$loginAtom = Atom(name: '_LoginStore.login', context: context);

  @override
  Observable<LoginModel?> get login {
    _$loginAtom.reportRead();
    return super.login;
  }

  @override
  set login(Observable<LoginModel?> value) {
    _$loginAtom.reportWrite(value, super.login, () {
      super.login = value;
    });
  }

  late final _$loginWithPhoneAtom =
      Atom(name: '_LoginStore.loginWithPhone', context: context);

  @override
  Observable<LoginWithPhoneModel?> get loginWithPhone {
    _$loginWithPhoneAtom.reportRead();
    return super.loginWithPhone;
  }

  @override
  set loginWithPhone(Observable<LoginWithPhoneModel?> value) {
    _$loginWithPhoneAtom.reportWrite(value, super.loginWithPhone, () {
      super.loginWithPhone = value;
    });
  }

  late final _$loginWithPhone2Atom =
      Atom(name: '_LoginStore.loginWithPhone2', context: context);

  @override
  Observable<LoginWithPhoneModel?> get loginWithPhone2 {
    _$loginWithPhone2Atom.reportRead();
    return super.loginWithPhone2;
  }

  @override
  set loginWithPhone2(Observable<LoginWithPhoneModel?> value) {
    _$loginWithPhone2Atom.reportWrite(value, super.loginWithPhone2, () {
      super.loginWithPhone2 = value;
    });
  }

  late final _$deleteDeviceAtom =
      Atom(name: '_LoginStore.deleteDevice', context: context);

  @override
  Observable<Map<String, dynamic>> get deleteDevice {
    _$deleteDeviceAtom.reportRead();
    return super.deleteDevice;
  }

  @override
  set deleteDevice(Observable<Map<String, dynamic>> value) {
    _$deleteDeviceAtom.reportWrite(value, super.deleteDevice, () {
      super.deleteDevice = value;
    });
  }

  late final _$loginWithWtAtom =
      Atom(name: '_LoginStore.loginWithWt', context: context);

  @override
  Observable<LoginWithWtModel?> get loginWithWt {
    _$loginWithWtAtom.reportRead();
    return super.loginWithWt;
  }

  @override
  set loginWithWt(Observable<LoginWithWtModel?> value) {
    _$loginWithWtAtom.reportWrite(value, super.loginWithWt, () {
      super.loginWithWt = value;
    });
  }

  late final _$verifyforgotOtpWithEmailAtom =
      Atom(name: '_LoginStore.verifyforgotOtpWithEmail', context: context);

  @override
  Observable<LoginWithPhoneModel?> get verifyforgotOtpWithEmail {
    _$verifyforgotOtpWithEmailAtom.reportRead();
    return super.verifyforgotOtpWithEmail;
  }

  @override
  set verifyforgotOtpWithEmail(Observable<LoginWithPhoneModel?> value) {
    _$verifyforgotOtpWithEmailAtom
        .reportWrite(value, super.verifyforgotOtpWithEmail, () {
      super.verifyforgotOtpWithEmail = value;
    });
  }

  late final _$errorMessageOtpAtom =
      Atom(name: '_LoginStore.errorMessageOtp', context: context);

  @override
  Observable<ErrorMessageModel?> get errorMessageOtp {
    _$errorMessageOtpAtom.reportRead();
    return super.errorMessageOtp;
  }

  @override
  set errorMessageOtp(Observable<ErrorMessageModel?> value) {
    _$errorMessageOtpAtom.reportWrite(value, super.errorMessageOtp, () {
      super.errorMessageOtp = value;
    });
  }

  late final _$forgotPassWithMailAtom =
      Atom(name: '_LoginStore.forgotPassWithMail', context: context);

  @override
  Observable<ForgotPasswordModel?> get forgotPassWithMail {
    _$forgotPassWithMailAtom.reportRead();
    return super.forgotPassWithMail;
  }

  @override
  set forgotPassWithMail(Observable<ForgotPasswordModel?> value) {
    _$forgotPassWithMailAtom.reportWrite(value, super.forgotPassWithMail, () {
      super.forgotPassWithMail = value;
    });
  }

  late final _$settingsDataAtom =
      Atom(name: '_LoginStore.settingsData', context: context);

  @override
  Observable<GetSettingsDataModel?> get settingsData {
    _$settingsDataAtom.reportRead();
    return super.settingsData;
  }

  @override
  set settingsData(Observable<GetSettingsDataModel?> value) {
    _$settingsDataAtom.reportWrite(value, super.settingsData, () {
      super.settingsData = value;
    });
  }

  late final _$_LoginStoreActionController =
      ActionController(name: '_LoginStore', context: context);

  @override
  void _setSettingsDetails(GetSettingsDataModel value) {
    final _$actionInfo = _$_LoginStoreActionController.startAction(
        name: '_LoginStore._setSettingsDetails');
    try {
      return super._setSettingsDetails(value);
    } finally {
      _$_LoginStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
isRemoveLoading: ${isRemoveLoading},
isLoadingSettings: ${isLoadingSettings},
errorMessage: ${errorMessage},
login: ${login},
loginWithPhone: ${loginWithPhone},
loginWithPhone2: ${loginWithPhone2},
deleteDevice: ${deleteDevice},
loginWithWt: ${loginWithWt},
verifyforgotOtpWithEmail: ${verifyforgotOtpWithEmail},
errorMessageOtp: ${errorMessageOtp},
forgotPassWithMail: ${forgotPassWithMail},
settingsData: ${settingsData}
    ''';
  }
}
