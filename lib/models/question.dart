class Question {
  final int? id;
  final String examType;
  final String question;
  final String aAlternative;
  final String bAlternative;
  final String? cAlternative;
  final String? dAlternative;
  final String? eAlternative;
  final String correctAnswer;
  final String? secondAnswer;
  final String? explanation;
  final String? explanationUrl;
  bool? answeredRight;
  Set<String> selectedAnswers = {};

  Question({
    this.id,
    required this.examType,
    required this.question,
    required this.aAlternative,
    required this.bAlternative,
    this.cAlternative,
    this.dAlternative,
    this.eAlternative,
    required this.correctAnswer,
    this.secondAnswer,
    this.explanation,
    this.explanationUrl,
    this.answeredRight,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'examType': examType,
      'question': question,
      'aAlternative': aAlternative,
      'bAlternative': bAlternative,
      'cAlternative': cAlternative,
      'dAlternative': dAlternative,
      'eAlternative': eAlternative,
      'correctAnswer': correctAnswer,
      'secondAnswer': secondAnswer,
      'explanation': explanation,
      'explanationUrl': explanationUrl,
      'answeredRight': answeredRight == null ? null : (answeredRight! ? 1 : 0),
    };
  }

  static Question fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      examType: map['examType'] as String,
      question: map['question'] as String,
      aAlternative: map['aAlternative'] as String,
      bAlternative: map['bAlternative'] as String,
      cAlternative: map['cAlternative'] as String?,
      dAlternative: map['dAlternative'] as String?,
      eAlternative: map['eAlternative'] as String?,
      correctAnswer: map['correctAnswer'] as String,
      secondAnswer: map['secondAnswer'] as String?,
      explanation: map['explanation'] as String?,
      explanationUrl: map['explanationUrl'] as String?,
      answeredRight: map['answeredRight'] == null ? null : map['answeredRight'] == 1,
    );
  }

  // Helper method to check if question has multiple answers
  bool get hasMultipleAnswers => secondAnswer != null;

  Set<String> get correctAnswers {
    Set<String> answers = {correctAnswer};
    if (secondAnswer != null) {
      answers.add(secondAnswer!);
    }
    return answers;
  }

  bool isAnswerCorrect() {
    if (hasMultipleAnswers) {
      return selectedAnswers.length == correctAnswers.length &&
             correctAnswers.every((answer) => selectedAnswers.contains(answer));
    }
    return selectedAnswers.length == 1 && selectedAnswers.first == correctAnswer;
  }

}
