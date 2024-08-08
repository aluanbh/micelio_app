import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:micelio_app/auth/encryption_service.dart';
import 'package:micelio_app/screens/home/home.dart';
import 'package:micelio_app/screens/login/login.dart';
import 'package:micelio_app/screens/passwordRecovery/passwordRecovery.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? savedUid = prefs.getString('uid');
  String decryptedUid = EncryptionService.decryptString(savedUid ?? "");
  print("decryptedUid: $decryptedUid");
  runApp(MyApp(savedUid: savedUid));
}

class MyApp extends StatelessWidget {
  final String? savedUid;
  const MyApp({Key? key, required this.savedUid}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Micélio App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: savedUid != null ? HomePage() : LoginPage(),
      routes: {
        "/home": (context) => const HomePage(),
        "/login": (context) => LoginPage(),
        "/password-recovery": (context) => RecoveryPage(),
      },
    );
  }
}
