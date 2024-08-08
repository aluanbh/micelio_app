import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:micelio_app/auth/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class RecoveryPage extends StatefulWidget {
  @override
  _RecoveryPageState createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _email = "";
  String _password = "";

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      // backgroundColor: Colors.black,
      body: SizedBox(
        height: height,
        width: width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            logoSide(width, height),
            formSide(width, height),
          ],
        ),
      ),
    );
  }

  Expanded logoSide(double width, double height) {
    return Expanded(
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(70, 20, 70, 10),
            child: Image.asset(
              'assets/images/logoMiceliobranca.png',
              width: width > 600 ? width * 0.2 : width * 0.5,
            ),
          ),
        ),
      ),
    );
  }

  double getHorizontalPadding(double width) {
    if (width < 360) {
      return 10;
    } else if (width < 600) {
      return 50;
    } else if (width < 768) {
      return 150;
    } else if (width < 992) {
      return 80;
    } else if (width < 1200) {
      return 100;
    } else if (width < 1500) {
      return 150;
    }
    return 250;
  }

  //um form expanded stateful widget
  Expanded formSide(double width, double height) {
    return Expanded(
      child: Container(
        height: height,
        color: Colors.blueAccent[800],
        child: Center(
          child: Padding(
            padding:
                EdgeInsets.symmetric(horizontal: getHorizontalPadding(width)),
            child: Form(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(
                        color: Color.fromARGB(149, 108, 81, 2),
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromARGB(149, 108, 81, 2),
                      ),
                      //cor na borda
                      borderRadius: BorderRadius.circular(
                          10.0), // Set your desired radius
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(149, 108, 81, 2),
                          ),
                          hintText: "E-mail",
                          border: InputBorder.none, // Remove default border
                        ),
                        style: TextStyle(color: Colors.grey.shade800),
                        onChanged: (value) => _email = value,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: Colors.black,
                    ),
                    child: InkWell(
                      onTap: _recoverPassword,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Text(
                          "RECUPERAR SENHA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, "/login");
                    },
                    child: Text(
                      "Voltar ao login",
                      style: TextStyle(
                        //cor azul e sublinhado
                        color: Color.fromARGB(149, 108, 81, 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _recoverPassword() async {
    try {
      await _auth.sendPasswordResetEmail(email: _email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("E-mail de recuperação de senha enviado."),
        ),
      );
      //ir para a tela de login
      Navigator.pushReplacementNamed(context, "/login");
    } on FirebaseAuthException catch (e) {
      switch (e.message) {
        case "The email address is badly formatted.":
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("O endereço de e-mail está mal formatado."),
            ),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Digite um e-mail válido."),
            ),
          );
      }
      print('erro: ${e.message}');
    }
  }
}
