class Question {
  final int id;
  final String examType;
  final String questionText;
  final List<String> answers;
  final int correctAnswerIndex;
  final bool isPremium;

  Question({
    required this.id,
    required this.examType,
    required this.questionText,
    required this.answers,
    required this.correctAnswerIndex,
    required this.isPremium,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'examType': examType,
      'questionText': questionText,
      'answers': answers.join('|'),
      'correctAnswerIndex': correctAnswerIndex,
      'isPremium': isPremium ? 1 : 0,
    };
  }

  static Question fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      examType: map['examType'],
      questionText: map['questionText'],
      answers: (map['answers'] as String).split('|'),
      correctAnswerIndex: map['correctAnswerIndex'],
      isPremium: map['isPremium'] == 1,
    );
  }
}