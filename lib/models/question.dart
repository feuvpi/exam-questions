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
      correctAnswer: map['correctAnswer'] as String,
      explanation: map['explanation'] as String?,
      explanationUrl: map['explanationUrl'] as String?,
      answeredRight: map['answeredRight'] == null ? null : map['answeredRight'] == 1,
    );
  }
}
