import 'package:flutter/material.dart';
import '../models/question_filter.dart';
import '../services/database_helper.dart';
import '../models/question.dart';

class QuestionScreen extends StatefulWidget {
  final String examType;
  const QuestionScreen({Key? key, required this.examType}) : super(key: key);

  @override
  _QuestionScreenState createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> with SingleTickerProviderStateMixin {
  late Future<List<Question>> _questionsFuture;
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  QuestionFilter _currentFilter = QuestionFilter.unanswered;
  late Future<Map<String, int>> _statssFuture;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _statssFuture = DatabaseHelper.instance.getQuestionStats(widget.examType);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    setState(() {
      _questionsFuture = DatabaseHelper.instance.getFilteredQuestions(
        widget.examType,
        _currentFilter,
      );
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Filter Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232F3E),
                ),
              ),
              SizedBox(height: 16),
              ...QuestionFilter.values.map(
                (filter) => ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _currentFilter == filter
                          ? Color(0xFFFF9900)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      filter.icon,
                      color: _currentFilter == filter
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                  title: Text(
                    filter.displayName,
                    style: TextStyle(
                      color: _currentFilter == filter
                          ? Color(0xFF232F3E)
                          : Colors.grey[600],
                      fontWeight: _currentFilter == filter
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _currentFilter = filter);
                    Navigator.pop(context);
                    _currentQuestionIndex = 0;
                    _loadQuestions();
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

void _answerQuestion(String selectedAnswer) async {
  Question currentQuestion = _questions[_currentQuestionIndex];

  // Add the selected answer to the set
  setState(() {
    if (currentQuestion.hasMultipleAnswers) {
      // For multiple answers, toggle the selection
      if (currentQuestion.selectedAnswers.contains(selectedAnswer)) {
        currentQuestion.selectedAnswers.remove(selectedAnswer);
      } else {
        currentQuestion.selectedAnswers.add(selectedAnswer);
      }
    } else {
      // For single answer, replace the selection
      currentQuestion.selectedAnswers = {selectedAnswer};
    }
  });

  // For multiple answers, wait until all required answers are selected
  if (currentQuestion.hasMultipleAnswers) {
    if (currentQuestion.selectedAnswers.length < currentQuestion.correctAnswers.length) {
      // Show hint that more answers are needed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Please select ${currentQuestion.correctAnswers.length - currentQuestion.selectedAnswers.length} more answer(s)',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
  }

  // Check if answer is correct using isAnswerCorrect()
  bool isCorrect = currentQuestion.isAnswerCorrect();

  await DatabaseHelper.instance.updateQuestionAnswer(currentQuestion.id, isCorrect);

  setState(() {
    currentQuestion.answeredRight = isCorrect;
  });

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(
          isCorrect ? Icons.check_circle : Icons.cancel,
          color: Colors.white,
        ),
        SizedBox(width: 8),
        Flexible(  // Added this wrapper
          child: Text(
            isCorrect 
                ? 'Correct!' 
                : currentQuestion.hasMultipleAnswers 
                    ? 'Incorrect. Remember this question requires multiple answers.' 
                    : 'Incorrect. Try again!',
            style: TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,  // Added overflow handling
            maxLines: 2,  // Optional: limit number of lines
          ),
        ),
      ],
    ),
    backgroundColor: isCorrect ? Colors.green : Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    margin: EdgeInsets.all(8),  // Added margin for better floating appearance
    duration: Duration(seconds: 3),  // Optional: adjust duration as needed
  ),
);
}
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _animationController.reset();
      setState(() {
        _currentQuestionIndex++;
      });
      _animationController.forward();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _animationController.reset();
      setState(() {
        _currentQuestionIndex--;
      });
      _animationController.forward();
    }
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: BackButton(color: Colors.white),
      actions: [
        FutureBuilder<Map<String, int>>(
          future: _statssFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox();
            final stats = snapshot.data!;
            return IconButton(
              icon: Icon(Icons.analytics_outlined, color: Colors.white),
              onPressed: () => _showStatsDialog(stats),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: Colors.white),
          onPressed: _showFilterDialog,
        ),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232F3E),
            Color(0xFF1A222E),
          ],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<List<Question>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9900)),
                ),
              );
            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            _questions = snapshot.data!;
            Question currentQuestion = _questions[_currentQuestionIndex];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: Colors.grey[800],
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9900)),
                  ),

                  // Question counter
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF9900),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // New question header with animation
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: _buildQuestionHeader(currentQuestion),
                            ),
                          ),
                          SizedBox(height: 24),
                          // Answer options
                          ..._buildAnswerButtons(currentQuestion),
                        ],
                      ),
                    ),
                  ),

                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildNavigationButton(
                          onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                          icon: Icons.arrow_back_ios,
                          label: 'Previous',
                        ),
                        _buildNavigationButton(
                          onPressed: _currentQuestionIndex < _questions.length - 1 
                              ? _nextQuestion 
                              : null,
                          icon: Icons.arrow_forward_ios,
                          label: 'Next',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}



  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentFilter.icon,
            size: 80,
            color: Color(0xFFFF9900).withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            'No ${_currentFilter.displayName.toLowerCase()} questions available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showFilterDialog,
            icon: Icon(Icons.filter_list),
            label: Text('Change Filter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF9900),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(Map<String, int> stats) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Progress Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF232F3E),
                ),
              ),
              SizedBox(height: 24),
              _buildStatTile('Total Questions', stats['total']!, Icons.format_list_numbered,
                  Color(0xFF232F3E)),
              _buildStatTile('Answered', stats['answered']!, Icons.done_all,
                  Colors.blue),
              _buildStatTile('Correct', stats['correct']!, Icons.check_circle_outline,
                  Colors.green),
              _buildStatTile('Incorrect', stats['incorrect']!, Icons.cancel_outlined,
                  Colors.red),
              _buildStatTile('Remaining', stats['unanswered']!, Icons.help_outline,
                  Colors.orange),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF9900),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, int value, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF232F3E),
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    Question currentQuestion = _questions[_currentQuestionIndex];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF9900)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                  decoration: BoxDecoration(
                    color: Color(0xFFFF9900),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 24),
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          currentQuestion.question,
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFF232F3E),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ..._buildAnswerButtons(currentQuestion),
                ],
              ),
            ),
          ),
          Padding(
  padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildNavigationButton(
        onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
        icon: Icons.arrow_back_ios,
        label: 'Previous',
      ),
      _buildNavigationButton(
        onPressed: _currentQuestionIndex < _questions.length - 1 
            ? _nextQuestion 
            : null,
        icon: Icons.arrow_forward_ios,
        label: 'Next',
      ),
    ],
  ),
),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
  required VoidCallback? onPressed,
  required IconData icon,
  required String label,
}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: onPressed == null 
          ? Colors.grey[300] 
          : Color(0xFFFF9900), // AWS Orange
      foregroundColor: onPressed == null 
          ? Colors.grey[600] 
          : Colors.black,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: onPressed == null ? 0 : 4,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon == Icons.arrow_back_ios) 
          Icon(icon, size: 18),
        if (icon == Icons.arrow_back_ios) 
          SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (icon == Icons.arrow_forward_ios) 
          SizedBox(width: 8),
        if (icon == Icons.arrow_forward_ios) 
          Icon(icon, size: 18),
      ],
    ),
  );
}

List<Widget> _buildAnswerButtons(Question question) {
  // Create answers array only with non-null and non-empty alternatives
  final answers = [
    if (question.aAlternative.isNotEmpty)
      {'label': 'A', 'text': question.aAlternative},
    if (question.bAlternative.isNotEmpty)
      {'label': 'B', 'text': question.bAlternative},
    if (question.cAlternative?.isNotEmpty == true)  // Handle nullable string
      {'label': 'C', 'text': question.cAlternative!},
    if (question.dAlternative?.isNotEmpty == true)  // Handle nullable string
      {'label': 'D', 'text': question.dAlternative!},
    if (question.eAlternative?.isNotEmpty == true)  // Handle nullable string
      {'label': 'E', 'text': question.eAlternative!},
  ];

  return answers.map((answer) {
    String label = answer['label'] as String;
    bool isSelected = question.selectedAnswers.contains(label);
    bool showResult = question.answeredRight != null;
    bool isCorrect = question.correctAnswers.contains(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: showResult
                  ? isCorrect
                      ? Color(0xFFE6F4EA)  // Light green for correct
                      : isSelected
                          ? Color(0xFFFCE8E8)  // Light red for wrong selection
                          : Colors.white
                  : isSelected
                      ? Color(0xFFE6F3FF)  // Light blue for selection
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: showResult
                    ? isCorrect
                        ? Colors.green.withOpacity(0.5)
                        : isSelected
                            ? Colors.red.withOpacity(0.5)
                            : Colors.transparent
                    : isSelected
                        ? Color(0xFFFF9900)
                        : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: question.answeredRight == null
                    ? () => _answerQuestion(label)
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: showResult
                              ? isCorrect
                                  ? Colors.green.withOpacity(0.1)
                                  : isSelected
                                      ? Colors.red.withOpacity(0.1)
                                      : Colors.grey[100]
                              : isSelected
                                  ? Color(0xFFFF9900).withOpacity(0.1)
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: showResult
                                  ? isCorrect
                                      ? Colors.green
                                      : isSelected
                                          ? Colors.red
                                          : Color(0xFF232F3E)
                                  : isSelected
                                      ? Color(0xFFFF9900)
                                      : Color(0xFF232F3E),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          answer['text'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            color: showResult
                                ? isCorrect
                                    ? Colors.green[700]
                                    : isSelected
                                        ? Colors.red[700]
                                        : Color(0xFF232F3E)
                                : Color(0xFF232F3E),
                            height: 1.5,
                          ),
                        ),
                      ),
                      if (question.answeredRight != null)
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : isSelected
                                  ? Icons.cancel
                                  : null,
                          color: isCorrect
                              ? Colors.green
                              : Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }).toList();
}
Widget _buildQuestionHeader(Question question) {
  return Column(
    children: [
      if (question.hasMultipleAnswers)
        Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Select ${question.correctAnswers.length} correct answers',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          question.question,
          style: TextStyle(
            fontSize: 20,
            color: Color(0xFF232F3E),
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}


}