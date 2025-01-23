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
    // await DatabaseHelper.instance.resetDatabase();
    final dbHelper = DatabaseHelper.instance;
    final dbPath = await dbHelper.getDatabasePath(); // Add this line
    print('Database path: $dbPath'); // Add this line

// Initialize database with bundled data
    await dbHelper.initDatabase();

    // await DatabaseHelper.populateDatabaseFromUrls([
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-1.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-2.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-4.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-5.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-6.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-7.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-8.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-9.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-10.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-11.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-12.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-13.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-14.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-15.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-16.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-16.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-18.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-19.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-20.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-21.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-22.md',
    //   // 'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-23.md',
    // ]);
  } catch (e, stackTrace) {
    logger.e('Error during database population',
        error: e, stackTrace: stackTrace);
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
