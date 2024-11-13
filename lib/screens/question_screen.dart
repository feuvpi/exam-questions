import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/question.dart';

class QuestionScreen extends StatefulWidget {
  final String examType;

  const QuestionScreen({Key? key, required this.examType}) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late Future<List<Question>> _questionsFuture;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;

  @override
  void initState() {
    super.initState();
    _questionsFuture = DatabaseHelper.instance.getQuestions(widget.examType);
  }

  Future<List<Question>> _loadQuestions() async {
    return await DatabaseHelper.instance
        .getUnansweredQuestions(widget.examType);
  }

  void _answerQuestion(String selectedAnswer) async {
    Question currentQuestion = _questions[_currentQuestionIndex];
    bool isCorrect = selectedAnswer == currentQuestion.correctAnswer;

    await DatabaseHelper.instance
        .updateQuestionAnswer(currentQuestion.id, isCorrect);

    setState(() {
      currentQuestion.answeredRight = isCorrect;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.examType),
        elevation: 0,
        backgroundColor: Colors.blue[700],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[700]!, Colors.blue[100]!],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<Question>>(
            future: _questionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                print("Error loading questions: ${snapshot.error}");
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                print("No questions found for ${widget.examType}");
                return Center(
                    child: Text('No unanswered questions available.'));
              } else {
                _questions = snapshot.data!;
                print("Loaded ${_questions.length} questions");
                return _buildQuestionContent();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionContent() {
    Question currentQuestion = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
            style: TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                currentQuestion.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: ListView(
              children: _buildAnswerButtons(currentQuestion),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                child: Text('Previous'),
              ),
              ElevatedButton(
                onPressed: _currentQuestionIndex < _questions.length - 1
                    ? _nextQuestion
                    : null,
                child: Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnswerButtons(Question question) {
    final answers = [
      {'label': 'A', 'text': question.aAlternative},
      {'label': 'B', 'text': question.bAlternative},
      if (question.cAlternative != null)
        {'label': 'C', 'text': question.cAlternative!},
      if (question.dAlternative != null)
        {'label': 'D', 'text': question.dAlternative!},
    ];

    return answers.map((answer) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: question.answeredRight == null
              ? Colors.white
              : answer['label'] == question.correctAnswer
                  ? Colors.green[100]
                  : Colors.red[100],
          child: InkWell(
            onTap: question.answeredRight == null
                ? () => _answerQuestion(answer['label'] as String)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    question.answeredRight == null
                        ? Icons.circle_outlined
                        : answer['label'] == question.correctAnswer
                            ? Icons.check_circle
                            : Icons.cancel,
                    color: Colors.blue[700],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${answer['label']}. ${answer['text']}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
