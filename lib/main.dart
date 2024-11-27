import 'package:flutter/material.dart';
import 'screens/SplashScreen.dart';
import 'services/database_helper.dart';

// void main() {
//   runApp(MyApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await DatabaseHelper.printDatabaseLocation();
  await DatabaseHelper.populateDatabaseFromUrls([
    'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-1.md',
    'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-2.md',
    'https://raw.githubusercontent.com/kananinirav/AWS-Certified-Cloud-Practitioner-Notes/master/practice-exam/practice-exam-3.md',
    // Add more URLs here
  ]);
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
