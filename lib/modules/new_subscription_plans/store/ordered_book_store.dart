import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shusruta_lms/modules/dashboard/store/internet_check_store.dart';
import 'package:shusruta_lms/modules/new_subscription_plans/model/ordered_book_model.dart';

import '../../../helpers/constants.dart';

part 'ordered_book_store.g.dart';

class OrderedBookStore = _OrderedBookStore with _$OrderedBookStore;

abstract class _OrderedBookStore extends InternetStore with Store {
  @observable
  bool isLoading = false;

  @observable
  String? error;

  @observable
  ObservableList<OrderedBookModel> orderedBooks = ObservableList<OrderedBookModel>();

  @action
  Future<void> getAllUserBooks() async {
    await checkConnectionStatus();
    if (!isConnected) {
      error = "No internet connection";
      return;
    }

    isLoading = true;
    error = null;
    
    try {
      // Get token from shared preferences or use the hardcoded one for demonstration
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString("token") ?? 
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiI2NzBmY2YyMzRkN2ZmYjMwNGE2Njg1YjY6QWQyYUZoQnQiLCJpYXQiOjE3NDY1NDc1MzJ9.Olr2BpNW2yf_KggvEe1X_-SDBB0mRIju0gFr7tDyqWU";
      
      // Make API call
      final response = await http.get(
        Uri.parse('$baseUrl/getAllUserBook'),
        headers: {
          'Content-Type': 'application/json', 
          'Authorization': token,
        },
      );
      
      log("getAllUserBooks response: ${response.body}");
      
      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonData = jsonDecode(response.body);
          orderedBooks.clear();
          orderedBooks.addAll(jsonData.map((item) => OrderedBookModel.fromJson(item)).toList());
        } catch (e) {
          log("Error parsing response: $e");
          error = 'Failed to parse ordered books: $e';
        }
      } else if (response.statusCode == 500) {
        // Handle server error
        log("Server error: ${response.body}");
        error = 'Server error occurred';
      } else {
        // Handle other errors
        log("API error: ${response.statusCode} - ${response.body}");
        error = 'Failed to fetch ordered books';
      }
    } catch (e) {
      debugPrint('Error fetching ordered books: $e');
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }
} 