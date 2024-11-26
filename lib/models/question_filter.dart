

import 'package:flutter/material.dart';

enum QuestionFilter {
  unanswered,
  all,
  answeredCorrect,
  answeredIncorrect,
  answered
}

extension QuestionFilterExtension on QuestionFilter {
  String get displayName {
    switch (this) {
      case QuestionFilter.unanswered:
        return 'Unanswered';
      case QuestionFilter.all:
        return 'All Questions';
      case QuestionFilter.answeredCorrect:
        return 'Correct Answers';
      case QuestionFilter.answeredIncorrect:
        return 'Incorrect Answers';
      case QuestionFilter.answered:
        return 'All Answered';
    }
  }

  IconData get icon {
    switch (this) {
      case QuestionFilter.unanswered:
        return Icons.help_outline;
      case QuestionFilter.all:
        return Icons.list;
      case QuestionFilter.answeredCorrect:
        return Icons.check_circle_outline;
      case QuestionFilter.answeredIncorrect:
        return Icons.cancel_outlined;
      case QuestionFilter.answered:
        return Icons.done_all;
    }
  }
}