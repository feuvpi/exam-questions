import 'package:flutter/material.dart';
import 'question_screen.dart';
import '../services/database_helper.dart';

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> exams = [
    {'name': 'AWS Certified Cloud Practitioner', 'icon': Icons.cloud_outlined},
    {'name': 'AWS Certified Solutions Architect', 'icon': Icons.architecture},
    {'name': 'AWS Certified Developer', 'icon': Icons.code},
    {'name': 'AWS Certified SysOps Administrator', 'icon': Icons.settings_applications},
  ];

  MenuScreen({Key? key}) : super(key: key);

  Future<bool> _hasQuestionsForExam(String examType) async {
    final questions = await DatabaseHelper.instance.getQuestions(examType);
    return questions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AWS Certification Prep'),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Choose an exam to practice:',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      return FutureBuilder<bool>(
                        future: _hasQuestionsForExam(exams[index]['name']),
                        builder: (context, snapshot) {
                          final bool hasQuestions = snapshot.data ?? false;
                          return _buildExamCard(
                            context, 
                            exams[index], 
                            enabled: hasQuestions,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, {bool enabled = true}) {
    return Card(
      elevation: enabled ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: enabled ? Colors.white : Colors.grey[300],
      child: InkWell(
        onTap: enabled ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuestionScreen(examType: exam['name']),
            ),
          );
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                exam['icon'],
                size: 64,
                color: enabled ? Colors.blue[700] : Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                exam['name'],
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black87 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (!enabled) 
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No questions available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}