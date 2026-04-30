import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimer {
  Duration initialTime; // Initial duration
  late Duration remainingTime; // Remaining time
  Timer? _timer; // Timer for countdown
  DateTime? _startTime; // When the timer was started
  DateTime? _pauseTime; // When the timer was paused (for background handling)
  final ValueNotifier<String> timeNotifier = ValueNotifier<String>("00:00:00");
  bool _isRunning = false;

  CountdownTimer(String timeString)
      : initialTime = _parseTimeString(timeString) {
    remainingTime = initialTime;
    timeNotifier.value = _formatDuration(initialTime);
  }

  /// Parse time in "HH:MM:SS" format into a Duration
  static Duration _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 3) {
      throw const FormatException("Invalid time format. Use HH:MM:SS.");
    }
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;

    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  /// Format a duration as HH:MM:SS
  static String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Calculate remaining time based on elapsed time since start
  void _updateRemainingTime() {
    if (_startTime == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_startTime!);
    remainingTime = initialTime - elapsed;

    if (remainingTime.isNegative) {
      remainingTime = Duration.zero;
    }

    timeNotifier.value = _formatDuration(remainingTime);
  }

  /// Start the countdown
  void start(Function() onComplete) {
    if (_timer != null && _timer!.isActive) {
      stop();
    }

    _startTime = DateTime.now();
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();

      if (remainingTime.inSeconds <= 0) {
        timer.cancel();
        _isRunning = false;
        onComplete();
      }
    });
  }

  /// Resume timer after app comes back from background
  void resume(Function() onComplete) {
    if (!_isRunning) return;

    _updateRemainingTime(); // Update with actual elapsed time

    if (remainingTime.inSeconds <= 0) {
      _isRunning = false;
      onComplete();
      return;
    }

    // Restart the periodic timer
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();

      if (remainingTime.inSeconds <= 0) {
        timer.cancel();
        _isRunning = false;
        onComplete();
      }
    });
  }

  /// Pause timer (when app goes to background)
  void pause() {
    _pauseTime = DateTime.now();
    _timer?.cancel();
  }

  /// Stop the timer completely
  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _startTime = null;
    _pauseTime = null;
  }

  /// Reset the timer back to the initial time
  void reset() {
    stop();
    remainingTime = initialTime;
    timeNotifier.value = _formatDuration(initialTime);
  }

  /// Check if the timer is running
  bool get isRunning => _isRunning;

  /// Check if the timer is up
  bool get isTimerUp => remainingTime.inSeconds <= 0;

  /// Get current remaining time as string
  String getCurrentTime() {
    if (_isRunning && _startTime != null) {
      _updateRemainingTime();
    }
    return _formatDuration(remainingTime);
  }

  /// Dispose resources
  void dispose() {
    _timer?.cancel();
    timeNotifier.dispose();
  }
}