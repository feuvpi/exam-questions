import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'screens/SplashScreen.dart';
import 'services/database_helper.dart';

// void main() {
//   runApp(MyApp());`
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final logger = Logger();
  
  try {
    // Reset database to ensure we have the latest schema
    await DatabaseHelper.instance.resetDatabase();
    
    await DatabaseHelper.populateDatabaseFromUrls([
      'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-1.md',
      // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-2.md',
      // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-3.md',
    ]);
  } catch (e, stackTrace) {
    logger.e('Error during database population', error: e, stackTrace: stackTrace);
    // Continue with app launch even if database population fails
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Start with the login screen
    );
  }
}
