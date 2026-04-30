class ExamAnsModel {
  final String userExamId;
  final String questionId;
  final String selectedOption;
  final bool attempted;
  final bool attemptedMarkedForReview;
  final bool skipped;

  final String guess;
  final String? previousSelected;
  final bool markedForReview;
  final bool isSaved;
  final String time;
  final String timePerQuestion;

  ExamAnsModel({
    required this.userExamId,
    required this.questionId,
    required this.selectedOption,
    required this.attempted,
    required this.attemptedMarkedForReview,
    required this.skipped,
    this.previousSelected,
    this.isSaved = false,
    required this.guess,
    required this.markedForReview,
    required this.time,
    required this.timePerQuestion,
  });

  // Factory constructor to create an object from JSON
  factory ExamAnsModel.fromJson(Map<String, dynamic> json) {
    return ExamAnsModel(
      userExamId: json['userExam_id'],
      questionId: json['question_id'],
      selectedOption: json['selected_option'],
      attempted: json['attempted'],
      attemptedMarkedForReview: json['attempted_marked_for_review'],
      skipped: json['skipped'],
      guess: json['guess'],
      markedForReview: json['marked_for_review'],
      time: json['time'],
      timePerQuestion: json['timePerQuestion'],
    );
  }

  // Method to convert an object to JSON
  Map<String, dynamic> toJson() {
    return {
      'userExam_id': userExamId,
      'question_id': questionId,
      'selected_option': selectedOption,
      'attempted': attempted,
      'attempted_marked_for_review': attemptedMarkedForReview,
      'skipped': skipped,
      'guess': guess,
      'previousSelected': previousSelected,
      'isSaved': isSaved,
      'marked_for_review': markedForReview,
      'time': time,
      'timePerQuestion': timePerQuestion,
    };
  }
}

Map<String, int> analyzeQuestionStatus(
    List<ExamAnsModel> questions, int length) {
  int isAttempted = 0;
  int isMarkedForReview = 0;
  int isSkipped = 0;
  int isAttemptedMarkedForReview = 0;
  int isGuess = 0;

  for (var question in questions) {
    if (question.attempted) isAttempted++;
    if (question.markedForReview) isMarkedForReview++;
    if (question.skipped) isSkipped++;
    if (question.attemptedMarkedForReview) isAttemptedMarkedForReview++;
    if (question.guess.isNotEmpty) isGuess++;
  }

  return {
    'isAttempted': isAttempted,
    'isMarkedForReview': isMarkedForReview,
    'isSkipped': isSkipped,
    'isAttemptedMarkedForReview': isAttemptedMarkedForReview,
    'notVisited': length -
        (isAttempted +
            isSkipped +
            isMarkedForReview +
            isAttemptedMarkedForReview +
            isGuess),
    'isGuess': isGuess,
  };
}
