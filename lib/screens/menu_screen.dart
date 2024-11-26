import 'package:flutter/material.dart';
import 'question_screen.dart';
import '../services/database_helper.dart';

class MenuScreen extends StatelessWidget {
  final List<Map<String, dynamic>> exams = [
    {'name': 'AWS Certified Cloud Practitioner', 'icon': Icons.cloud_outlined, 'description': 'Foundation level certification for AWS Cloud understanding'},
    {'name': 'AWS Certified Solutions Architect', 'icon': Icons.architecture, 'description': 'Design and deploy systems on AWS infrastructure'},
    {'name': 'AWS Certified Developer', 'icon': Icons.code, 'description': 'Develop and maintain AWS-based applications'},
    {'name': 'AWS Certified SysOps Administrator', 'icon': Icons.settings_applications, 'description': 'Deploy, manage, and operate AWS systems'},
  ];

  MenuScreen({Key? key}) : super(key: key);

  Future<bool> _hasQuestionsForExam(String examType) async {
    final questions = await DatabaseHelper.instance.getQuestions(examType);
    return questions.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF232F3E), // AWS Navy
              Color(0xFF1A222E), // Darker AWS Navy
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'AWS Certification Prep',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF232F3E),
                              Color(0xFF232F3E).withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.cloud_circle,
                          size: 200,
                          color: Color(0xFFFF9900).withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: Color(0xFF232F3E),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Choose your certification path',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    SizedBox(height: 24),
                    ...exams.map((exam) => Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: FutureBuilder<bool>(
                        future: _hasQuestionsForExam(exam['name']),
                        builder: (context, snapshot) {
                          final bool hasQuestions = snapshot.data ?? false;
                          return _buildExamCard(
                            context,
                            exam,
                            enabled: hasQuestions,
                          );
                        },
                      ),
                    )).toList(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam, {bool enabled = true}) {
    return Card(
      elevation: enabled ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: enabled ? Colors.white : Colors.grey[300],
      child: InkWell(
        onTap: enabled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuestionScreen(examType: exam['name']),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: enabled ? Color(0xFFFF9900) : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      exam['icon'],
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam['name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: enabled ? Color(0xFF232F3E) : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          exam['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: enabled ? Colors.grey[600] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!enabled)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'No questions available',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}