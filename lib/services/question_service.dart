import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/question.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuestionService {
  static final Logger _logger = Logger();

  static List<Question> parseMarkdown2(String markdown) {
    List<Question> questions = [];
    RegExp questionRegex = RegExp(
      r'^\d+\.\s(.+?)\n\n(?:([A-D])\.\s(.+?)\n)+\n(?:Answer:\s*([A-D]))?(?:\n\nExplanation:\s*(.+?))?(?=\n\n\d+\.|\Z)',
      multiLine: true,
      dotAll: true,
    );
    int i = 0;
    for (Match match in questionRegex.allMatches(markdown)) {
      try {
        String questionText = match.group(1)!.trim();
        List<String> alternatives = [];
        RegExp optionRegex = RegExp(r'([A-D])\.\s(.+)');
        for (String line in match.group(0)!.split('\n')) {
          Match? optionMatch = optionRegex.firstMatch(line);
          if (optionMatch != null) {
            alternatives.add(optionMatch.group(2)!.trim());
          }
        }

        String correctAnswer = match.group(4) ?? '';
        String explanation = match.group(5)?.trim() ?? '';

        questions.add(Question(
          examType: 'AWS Certifed Cloud Practitioner',
          question: questionText,
          aAlternative: alternatives.length > 0 ? alternatives[0] : '',
          bAlternative: alternatives.length > 1 ? alternatives[1] : '',
          cAlternative: alternatives.length > 2 ? alternatives[2] : null,
          dAlternative: alternatives.length > 3 ? alternatives[3] : null,
          correctAnswer: correctAnswer,
          explanation: explanation,
        ));
        print("Processed and inserted questions from $questions[i]");
        i++;
      } catch (e) {
        _logger.w('Failed to parse question', error: e);
      }
    }

    return questions;
  }
}
