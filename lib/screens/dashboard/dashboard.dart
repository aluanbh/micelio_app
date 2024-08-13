import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashbordPage extends StatefulWidget {
  @override
  _DashbordPageState createState() => _DashbordPageState();
}

class _DashbordPageState extends State<DashbordPage> {
  String uid = "";
  String name = "";
  String email = "";
  String phone = "";
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _getUserDataFromSharedPreferences();
  }

  Future<void> _getUserDataFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String savedUid = prefs.getString('uid') ?? "";
    String savedName = prefs.getString('name') ?? "";
    String savedEmail = prefs.getString('email') ?? "";
    bool savedIsAdmin = prefs.getBool('isAdmin') ?? false;
    String savedPhone = prefs.getString('phone') ?? "";

    setState(() {
      uid = savedUid;
      name = savedName;
      email = savedEmail;
      isAdmin = savedIsAdmin;
      phone = savedPhone;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Olá, $name", // Use o userName obtido do Firestore
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            TextButton(
              child: Text("Logout"),
              onPressed: () async {
                FirebaseAuth.instance.signOut();
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),
    );
  }
}
