// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_class_main_screen_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$MeetingStore on _MeetingStoreBase, Store {
  late final _$meetingsAtom =
      Atom(name: '_MeetingStoreBase.meetings', context: context);

  @override
  ObservableList<ZoomLiveModel> get meetings {
    _$meetingsAtom.reportRead();
    return super.meetings;
  }

  @override
  set meetings(ObservableList<ZoomLiveModel> value) {
    _$meetingsAtom.reportWrite(value, super.meetings, () {
      super.meetings = value;
    });
  }

  late final _$meetingUpcomingAtom =
      Atom(name: '_MeetingStoreBase.meetingUpcoming', context: context);

  @override
  ObservableList<ZoomLiveModel> get meetingUpcoming {
    _$meetingUpcomingAtom.reportRead();
    return super.meetingUpcoming;
  }

  @override
  set meetingUpcoming(ObservableList<ZoomLiveModel> value) {
    _$meetingUpcomingAtom.reportWrite(value, super.meetingUpcoming, () {
      super.meetingUpcoming = value;
    });
  }

  late final _$fetchMeetingsAsyncAction =
      AsyncAction('_MeetingStoreBase.fetchMeetings', context: context);

  @override
  Future<void> fetchMeetings() {
    return _$fetchMeetingsAsyncAction.run(() => super.fetchMeetings());
  }

  late final _$fetchUpComingMeetingAsyncAction =
      AsyncAction('_MeetingStoreBase.fetchUpComingMeeting', context: context);

  @override
  Future<void> fetchUpComingMeeting() {
    return _$fetchUpComingMeetingAsyncAction
        .run(() => super.fetchUpComingMeeting());
  }

  @override
  String toString() {
    return '''
meetings: ${meetings},
meetingUpcoming: ${meetingUpcoming}
    ''';
  }
}
