import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/question.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class QuestionService {
  static final Logger _logger = Logger();

static List<Question> parseMarkdown(String markdown) {
    List<Question> questions = [];
    
    // Updated regex pattern to match the actual markdown format
    final questionPattern = RegExp(
      r'(\d+)\.\s+(.*?)\n\s+(?:- ([A-D])\.\s+(.*?)\n\s+)+\s+<details.*?>\s*<summary.*?>Answer.*?</summary>\s*Correct answer:\s*([A-D])',
      multiLine: true,
      dotAll: true,
    );

    final alternativePattern = RegExp(r'- ([A-D])\.\s+(.*?)\n');

    for (Match match in questionPattern.allMatches(markdown)) {
      try {
        final questionNumber = match.group(1);
        final questionText = match.group(2)?.trim();
        final correctAnswer = match.group(5)?.trim();
        
        if (questionText == null || correctAnswer == null) continue;

        // Find all alternatives for this question
        final questionBlock = match.group(0) ?? '';
        final alternatives = <String, String>{};
        
        for (Match altMatch in alternativePattern.allMatches(questionBlock)) {
          final letter = altMatch.group(1);
          final text = altMatch.group(2)?.trim();
          if (letter != null && text != null) {
            alternatives[letter] = text;
          }
        }

        if (alternatives.length < 2) {
          _logger.w('Question $questionNumber has insufficient alternatives');
          continue;
        }

        questions.add(Question(
          examType: 'AWS Certified Cloud Practitioner',
          question: questionText,
          aAlternative: alternatives['A'] ?? '',
          bAlternative: alternatives['B'] ?? '',
          cAlternative: alternatives['C'],
          dAlternative: alternatives['D'],
          correctAnswer: correctAnswer,
          explanation: '', // Explanation parsing could be added if needed
        ));

        _logger.i('Successfully parsed question $questionNumber');
      } catch (e) {
        _logger.e('Failed to parse question', error: e);
      }
    }

    return questions;
  }

  static Future<bool> processMarkdownUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final markdown = response.body;
        final questions = parseMarkdown(markdown);
        
        if (questions.isEmpty) {
          _logger.w('No questions parsed from $url');
          return false;
        }

        await DatabaseHelper.insertQuestions(questions);
        _logger.i('Successfully processed ${questions.length} questions from $url');
        return true;
      } else {
        _logger.e('Failed to fetch URL: $url, Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.e('Error processing URL: $url', error: e);
      return false;
    }
  }
}
