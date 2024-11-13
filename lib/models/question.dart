class Question {
  final int? id;
  final String examType;
  final String question;
  final String aAlternative;
  final String bAlternative;
  final String? cAlternative;
  final String? dAlternative;
  final String correctAnswer;
  final String? explanation;
  final String? explanationUrl;
  bool? answeredRight;

  Question({
    this.id,
    required this.examType,
    required this.question,
    required this.aAlternative,
    required this.bAlternative,
    this.cAlternative,
    this.dAlternative,
    required this.correctAnswer,
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
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'explanationUrl': explanationUrl,
      'answeredRight': answeredRight,
    };
  }

  static Question fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      examType: map['examType'],
      question: map['question'],
      aAlternative: map['aAlternative'],
      bAlternative: map['bAlternative'],
      cAlternative: map['cAlternative'],
      dAlternative: map['dAlternative'],
      correctAnswer: map['correctAnswer'],
      explanation: map['explanation'],
      explanationUrl: map['explanationUrl'],
      answeredRight: map['answeredRight'],
    );
  }
}
