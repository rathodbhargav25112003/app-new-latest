import 'dart:io';

void main() async {
  final files = [
    'lib/modules/reports/report_main_screen.dart',
    'lib/modules/reports/master reports/master_report_main.dart',
    'lib/modules/reports/trend_analysis.dart',
    'lib/modules/quiztest/quiz_solution_screen.dart',
    'lib/modules/test/test_report_screen.dart',
    'lib/modules/test/test_report_details_screen.dart',
    'lib/modules/masterTest/strength_weakness_graph.dart',
    'lib/modules/masterTest/master_test_report_details_screen.dart',
    'lib/modules/masterTest/master_test_report_screen.dart',
    'lib/modules/customtests/custom_test_report_screen.dart',
    'lib/modules/customtests/custom_test_report_details_screen.dart',
  ];

  for (final filePath in files) {
    final file = File(filePath);
    if (await file.exists()) {
      String content = await file.readAsString();
      content = content.replaceAll(
        "import 'package:circular_chart_flutter/circular_chart_flutter.dart';",
        "import 'package:shusruta_lms/helpers/forked_packages/circular_chart_flutter/lib/circular_chart_flutter.dart';",
      );
      await file.writeAsString(content);
      print('Updated: $filePath');
    } else {
      print('File not found: $filePath');
    }
  }
} 