import 'dart:convert';
import 'package:mobx/mobx.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/helpers/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shusruta_lms/models/zoom_meeting_live_model.dart';

// stores/meeting_store.dart

part 'live_class_main_screen_store.g.dart';

class MeetingStore = _MeetingStoreBase with _$MeetingStore;

abstract class _MeetingStoreBase with Store {
  @observable
  ObservableList<ZoomLiveModel> meetings = ObservableList<ZoomLiveModel>();

  @observable
  ObservableList<ZoomLiveModel> meetingUpcoming =
      ObservableList<ZoomLiveModel>();

  @action
  Future<void> fetchMeetings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response = await http.get(Uri.parse(getAllMeetingLive), headers: {
        'Authorization': token!,
      });
      if (response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        print("data: $data");
        print("responce: $data");
        meetings.clear();
        meetings.addAll(data.map((item) => ZoomLiveModel.fromJson(item)));
        print(meetings.length);
      } else if (response.statusCode == 500) {
        final List<dynamic> data = json.decode(response.body);
        print("data: $data");
        meetings.clear();
        meetings.addAll(data.map((item) => ZoomLiveModel.fromJson(item)));
        print(meetings.length);
      } else {
        throw Exception('Failed to load meetings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load meetings: $e');
    }
  }

  @action
  Future<void> fetchUpComingMeeting() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      final response =
          await http.get(Uri.parse(getAllMeetingUpcoming), headers: {
        'Authorization': token!,
      });
      if (response.statusCode == 201) {
        debugPrint("response meeting:${response.body}");
        final List<dynamic> data = json.decode(response.body);
        meetingUpcoming.clear();
        meetingUpcoming
            .addAll(data.map((item) => ZoomLiveModel.fromJson(item)));
        print(meetingUpcoming.length);
      } else if (response.statusCode == 500) {
        final List<dynamic> data = json.decode(response.body);
        print("data: $data");
        meetingUpcoming.clear();
        meetingUpcoming
            .addAll(data.map((item) => ZoomLiveModel.fromJson(item)));
        print(meetingUpcoming.length);
      } else {
        throw Exception('Failed to load meetings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to load meetings: $e');
    }
  }
}
