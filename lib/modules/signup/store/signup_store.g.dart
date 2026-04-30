// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signup_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$SignupStore on _SignupStore, Store {
  late final _$isLoadingAtom =
      Atom(name: '_SignupStore.isLoading', context: context);

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

  late final _$errorMessageAtom =
      Atom(name: '_SignupStore.errorMessage', context: context);

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

  late final _$errorMessageOtpAtom =
      Atom(name: '_SignupStore.errorMessageOtp', context: context);

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

  late final _$errorMessageOtp2Atom =
      Atom(name: '_SignupStore.errorMessageOtp2', context: context);

  @override
  Observable<ErrorMessageModel?> get errorMessageOtp2 {
    _$errorMessageOtp2Atom.reportRead();
    return super.errorMessageOtp2;
  }

  @override
  set errorMessageOtp2(Observable<ErrorMessageModel?> value) {
    _$errorMessageOtp2Atom.reportWrite(value, super.errorMessageOtp2, () {
      super.errorMessageOtp2 = value;
    });
  }

  late final _$signupAtom = Atom(name: '_SignupStore.signup', context: context);

  @override
  Observable<SignupModel?> get signup {
    _$signupAtom.reportRead();
    return super.signup;
  }

  @override
  set signup(Observable<SignupModel?> value) {
    _$signupAtom.reportWrite(value, super.signup, () {
      super.signup = value;
    });
  }

  late final _$signupWithPhoneAtom =
      Atom(name: '_SignupStore.signupWithPhone', context: context);

  @override
  Observable<SignupWithPhoneModel?> get signupWithPhone {
    _$signupWithPhoneAtom.reportRead();
    return super.signupWithPhone;
  }

  @override
  set signupWithPhone(Observable<SignupWithPhoneModel?> value) {
    _$signupWithPhoneAtom.reportWrite(value, super.signupWithPhone, () {
      super.signupWithPhone = value;
    });
  }

  late final _$registerWithEmailAtom =
      Atom(name: '_SignupStore.registerWithEmail', context: context);

  @override
  Observable<LoginWithPhoneModel?> get registerWithEmail {
    _$registerWithEmailAtom.reportRead();
    return super.registerWithEmail;
  }

  @override
  set registerWithEmail(Observable<LoginWithPhoneModel?> value) {
    _$registerWithEmailAtom.reportWrite(value, super.registerWithEmail, () {
      super.registerWithEmail = value;
    });
  }

  late final _$registerWithEmail2Atom =
      Atom(name: '_SignupStore.registerWithEmail2', context: context);

  @override
  Observable<LoginWithPhoneModel?> get registerWithEmail2 {
    _$registerWithEmail2Atom.reportRead();
    return super.registerWithEmail2;
  }

  @override
  set registerWithEmail2(Observable<LoginWithPhoneModel?> value) {
    _$registerWithEmail2Atom.reportWrite(value, super.registerWithEmail2, () {
      super.registerWithEmail2 = value;
    });
  }

  late final _$preparingexamsAtom =
      Atom(name: '_SignupStore.preparingexams', context: context);

  @override
  ObservableList<PreparingForModel?> get preparingexams {
    _$preparingexamsAtom.reportRead();
    return super.preparingexams;
  }

  @override
  set preparingexams(ObservableList<PreparingForModel?> value) {
    _$preparingexamsAtom.reportWrite(value, super.preparingexams, () {
      super.preparingexams = value;
    });
  }

  late final _$standardListAtom =
      Atom(name: '_SignupStore.standardList', context: context);

  @override
  ObservableList<StandardModel?> get standardList {
    _$standardListAtom.reportRead();
    return super.standardList;
  }

  @override
  set standardList(ObservableList<StandardModel?> value) {
    _$standardListAtom.reportWrite(value, super.standardList, () {
      super.standardList = value;
    });
  }

  @override
  String toString() {
    return '''
isLoading: ${isLoading},
errorMessage: ${errorMessage},
errorMessageOtp: ${errorMessageOtp},
errorMessageOtp2: ${errorMessageOtp2},
signup: ${signup},
signupWithPhone: ${signupWithPhone},
registerWithEmail: ${registerWithEmail},
registerWithEmail2: ${registerWithEmail2},
preparingexams: ${preparingexams},
standardList: ${standardList}
    ''';
  }
}
