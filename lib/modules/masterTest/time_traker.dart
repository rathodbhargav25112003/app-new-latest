// ignore_for_file: deprecated_member_use, unused_import, unused_field, unused_element, avoid_print, use_build_context_synchronously, library_private_types_in_public_api, non_constant_identifier_names

/// Pure-Dart stopwatch helper used by master-test screens to resume / persist
/// elapsed exam time. No UI surface — the AppTokens design-system migration
/// does not touch this file, its public API is preserved verbatim:
///   • `TimeTracker({String previousTime = '00:00:00'})`
///   • `void start()`
///   • `String stop()` — returns HH:MM:SS
///   • `String getCurrentTime()` — returns HH:MM:SS without stopping
///   • `void dispose()`
class TimeTracker {
  late Stopwatch _stopwatch;
  late Duration
      _previousDuration; // Marked as 'late' to initialize in constructor

  TimeTracker({String previousTime = '00:00:00'}) {
    // Initialize the stopwatch
    _stopwatch = Stopwatch();
    // Parse the previous time and convert it to a Duration
    _previousDuration = _parseTime(previousTime);
  }

  // Start the timer
  void start() {
    _stopwatch.start();
  }

  // Stop the timer and return the total time in '00:00:00' format
  String stop() {
    _stopwatch.stop();
    // Calculate the total time by adding previous time and elapsed time
    Duration totalTime = _previousDuration + _stopwatch.elapsed;
    return _formatDuration(totalTime);
  }

  // Get the current running time in '00:00:00' format without stopping the stopwatch
  String getCurrentTime() {
    // Calculate the total time by adding previous time and elapsed time
    Duration currentTime = _previousDuration + _stopwatch.elapsed;
    return _formatDuration(currentTime);
  }

  // Parse the previous time string '00:00:00' to Duration
  Duration _parseTime(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    int seconds = int.parse(parts[2]);
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  // Format a Duration to '00:00:00'
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  void dispose() {
    _stopwatch.stop();
    _stopwatch.reset();
    _previousDuration = Duration.zero;
  }
}
